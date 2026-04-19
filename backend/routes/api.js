const express = require('express');
const router = express.Router();
const db = require('../db');

// --- 1. Master Data ---
router.get('/races', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM RACES ORDER BY start_time ASC');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.get('/teams', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM TEAMS ORDER BY name ASC');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.get('/teams/:team_code/drivers', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT d.driver_code, d.name, d.nationality, c.contract_id 
            FROM CONTRACTS c 
            JOIN DRIVERS d ON c.driver_code = d.driver_code 
            WHERE c.team_code = ? AND c.is_active = 1
            ORDER BY d.name ASC
        `, [req.params.team_code]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 2. Module 1: Register to racing ---
router.get('/races/:race_code/teams/:team_code/entries', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT c.contract_id 
            FROM RACE_ENTRIES re
            JOIN CONTRACTS c ON re.contract_id = c.contract_id
            WHERE re.race_code = ? AND c.team_code = ?
        `, [req.params.race_code, req.params.team_code]);
        res.json(rows.map(r => r.contract_id));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/races/:race_code/teams/:team_code/entries', async (req, res) => {
    const { race_code, team_code } = req.params;
    const { contract_ids } = req.body;

    if (!Array.isArray(contract_ids) || contract_ids.length > 2) {
        return res.status(400).json({ error: 'Please submit maximum of 2 racers.' });
    }

    try {
        const connection = await db.getConnection();
        await connection.beginTransaction();
        try {
            const [existing] = await connection.query(`
                SELECT re.entry_id, re.contract_id 
                FROM RACE_ENTRIES re JOIN CONTRACTS c ON re.contract_id = c.contract_id
                WHERE re.race_code = ? AND c.team_code = ?
            `, [race_code, team_code]);
            const existingIds = existing.map(e => e.contract_id);

            const toDelete = existing.filter(e => !contract_ids.includes(e.contract_id));
            if (toDelete.length > 0) {
                const entryIdsToDelete = toDelete.map(e => e.entry_id);
                await connection.query(`DELETE FROM RESULTS WHERE entry_id IN (?)`, [entryIdsToDelete]);
                await connection.query(`DELETE FROM RACE_ENTRIES WHERE entry_id IN (?)`, [entryIdsToDelete]);
            }

            const toInsert = contract_ids.filter(id => !existingIds.includes(id));
            for (const cid of toInsert) {
                await connection.query(`INSERT INTO RACE_ENTRIES (race_code, contract_id) VALUES (?, ?)`, [race_code, cid]);
            }

            await connection.commit();
            res.json({ success: true, message: 'Sync successful' });
        } catch (txnErr) {
            await connection.rollback();
            throw txnErr;
        } finally {
            connection.release();
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 3. Module 2: Update Results ---
router.get('/races/:race_code/entries', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT re.entry_id, d.name AS driver_name, t.name AS team_name, re.race_code 
            FROM RACE_ENTRIES re 
            JOIN CONTRACTS c ON re.contract_id = c.contract_id 
            JOIN DRIVERS d ON c.driver_code = d.driver_code 
            JOIN TEAMS t ON c.team_code = t.team_code
            WHERE re.race_code = ?
            ORDER BY t.name ASC, d.name ASC
        `, [req.params.race_code]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/races/results', async (req, res) => {
    const { results } = req.body;

    try {
        const connection = await db.getConnection();
        await connection.beginTransaction();
        try {
            for (const r of results) {
                const endTime = r.end_time ? r.end_time : null;
                const laps = r.laps_completed ? r.laps_completed : 0;
                await connection.query(`
                    INSERT INTO RESULTS (entry_id, end_time, laps_completed, status)
                    VALUES (?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE 
                        end_time = VALUES(end_time),
                        laps_completed = VALUES(laps_completed),
                        status = VALUES(status)
                `, [r.entry_id, endTime, laps, r.status]);
            }

            if (results.length > 0) {
                const [raceData] = await connection.query(`SELECT race_code FROM RACE_ENTRIES WHERE entry_id = ?`, [results[0].entry_id]);
                if (raceData.length > 0) {
                    await connection.query(`CALL sp_calculate_points(?)`, [raceData[0].race_code]);
                }
            }

            await connection.commit();
            res.json({ success: true, message: 'Results saved successfully' });
        } catch (txnErr) {
            await connection.rollback();
            throw txnErr;
        } finally {
            connection.release();
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.delete('/results/:entry_id', async (req, res) => {
    try {
        await db.query('DELETE FROM RESULTS WHERE entry_id = ?', [req.params.entry_id]);
        res.json({ success: true, message: 'Result cleared' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 4. Module 3: Driver Standings ---
router.get('/standings/drivers', async (req, res) => {
    const { stage } = req.query;
    try {
        let query;
        let queryParams = [];

        if (stage) {
            query = `
                SELECT d.driver_code, d.name, d.nationality, t.name as team_name,
                SUM(vp.points) as total_score,
                SUM(CASE WHEN vp.status = 'Finished' THEN vp.finish_time_seconds ELSE 0 END) as total_time
                FROM DRIVERS d
                JOIN CONTRACTS c ON d.driver_code = c.driver_code AND c.is_active = 1
                JOIN TEAMS t ON c.team_code = t.team_code
                JOIN v_race_performance vp ON vp.driver_code = d.driver_code AND vp.team_code = t.team_code
                JOIN RACES r ON vp.race_code = r.race_code
                WHERE r.start_time <= (SELECT start_time FROM RACES WHERE race_code = ?)
                GROUP BY d.driver_code, d.name, d.nationality, t.name
                ORDER BY total_score DESC, total_time ASC
            `;
            queryParams = [stage];
        } else {
            query = `SELECT driver_code, name, nationality, team_name, total_score, total_season_time as total_time FROM v_driver_standings`;
        }

        const [rows] = await db.query(query, queryParams);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.get('/drivers/:driver_code/results', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT r.name as stage_name, 
                   (SELECT COUNT(*)+1 FROM v_race_performance vp2 WHERE vp2.race_code = vp.race_code AND vp2.status = 'Finished' AND vp2.finish_time_seconds < vp.finish_time_seconds) as finish_rank,
                   vp.points as score, vp.finish_time_seconds as time_to_finish, vp.status
            FROM v_race_performance vp
            JOIN RACES r ON vp.race_code = r.race_code
            WHERE vp.driver_code = ?
            ORDER BY r.start_time ASC
        `, [req.params.driver_code]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 5. Module 4: Team Standings ---
router.get('/standings/teams', async (req, res) => {
    const { stage } = req.query;
    try {
        let query;
        let queryParams = [];

        if (stage) {
            query = `
                SELECT t.team_code, t.name as team_name, t.brand,
                SUM(vp.points) as total_score,
                SUM(CASE WHEN vp.status = 'Finished' THEN vp.finish_time_seconds ELSE 0 END) as total_time
                FROM TEAMS t
                JOIN CONTRACTS c ON t.team_code = c.team_code AND c.is_active = 1
                JOIN v_race_performance vp ON vp.team_code = t.team_code AND vp.driver_code = c.driver_code
                JOIN RACES r ON vp.race_code = r.race_code
                WHERE r.start_time <= (SELECT start_time FROM RACES WHERE race_code = ?)
                GROUP BY t.team_code, t.name, t.brand
                ORDER BY total_score DESC, total_time ASC
            `;
            queryParams = [stage];
        } else {
            query = `SELECT team_code, team_name, brand, team_total_score as total_score, team_total_time as total_time FROM v_team_standings`;
        }

        const [rows] = await db.query(query, queryParams);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.get('/teams/:team_code/results', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT r.name as stage_name, 
            SUM(vp.points) as total_score, 
            SUM(CASE WHEN vp.status = 'Finished' THEN vp.finish_time_seconds ELSE 0 END) as total_time
            FROM v_race_performance vp
            JOIN RACES r ON vp.race_code = r.race_code
            WHERE vp.team_code = ?
            GROUP BY r.race_code, r.name, r.start_time
            ORDER BY r.start_time ASC
        `, [req.params.team_code]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
