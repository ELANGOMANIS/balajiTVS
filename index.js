
const express = require('express');
const mysql = require('mysql2');
const multer = require('multer');


const cors = require('cors');
const bodyParser = require('body-parser');
const csv = require('csv-parser');
const cron = require('node-cron');
const moment = require('moment');
const http = require('http');
const axios = require('axios');

const app = express();

// Settings
require("dotenv").config();
//console.log(process.env.WEATHER_API_KEY);
app.set('port', process.env.PORT || 3309);

// Middlewares
app.use(express.json());
app.use(cors());

// Configure multer storage
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });


const db = mysql.createConnection({
   host: 'localhost',
   user: 'root',
   password: 'root',
   database: 'vkcones',
});
// Connect to MySQL
db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
  } else {
    console.log('Connected to MySQL');
  }
});


//General auto save
async function insertDatacustomer(dataToInsertcustomer) {
  const apiUrl = 'http://localhost:3309/attandance_entry';

  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({ dataToInsertcustomer }),
    });

    if (response.status === 200) {
      console.log('TableData inserted successfully');
    } else {
      console.log('Failed to Table insert data');
      throw new Error('Failed to Table insert data');
    }
  } catch (error) {
    console.error('Error:', error);
    throw new Error('Error:', error);
  }
}
app.post('/attandance_entry', (req, res) => {
  const { dataToInsertcustomer } = req.body;

  // Assuming 'emp_code' and 'inDate' form a unique key in your table
  const sql = `
    INSERT INTO attendance
    SET ?
    ON DUPLICATE KEY UPDATE
      first_name = VALUES(first_name),
      inDate = VALUES(inDate),
      shiftType = VALUES(shiftType),
      check_in = VALUES(check_in),
      lunch_out = VALUES(lunch_out),
      lunch_in = VALUES(lunch_in),
      check_out = VALUES(check_out),
      latecheck_in = VALUES(latecheck_in),
      late_lunch = VALUES(late_lunch),
      earlycheck_out = VALUES(earlycheck_out),
      req_time = VALUES(req_time),
      act_time = VALUES(act_time),
      salary = VALUES(salary),
      salaryType = VALUES(salaryType),
      monthly_salary = VALUES(monthly_salary),
      remark = VALUES(remark)
  `;

  db.query(sql, dataToInsertcustomer, (err, result) => {
    if (err) {
      console.error('Error inserting/updating data:', err);
      res.status(500).json({ error: 'Error inserting/updating data' });
    } else {
      console.log('Data inserted/updated successfully');
      res.status(200).json({ message: 'Data inserted/updated successfully' });
    }
  });
});

async function fetchUnitEntriesGeneral() {
  try {
    const response = await axios.get('http://localhost:3309/attendance_view_general');

    console.log('Response status:', response.status);

    if (response.status === 200) {
      const data = response.data;
      //console.log('Fetched data:', data);
      return data;
    } else {
      throw new Error(`Error loading unit entries: ${response.status}`);
    }
  } catch (error) {
    console.error('Error fetching unit entries:', error.message);
    throw new Error(`Failed to load unit entries: ${error.message}`);
  }
}


app.get('/attendance_view_general', (req, res) => {
    const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format

    const sql = `
        SELECT
            e.emp_code,
            e.first_name,
            e.salary,
            e.salaryType,
            it.punch_time,
            s.shiftType,
            s.startTime,
            s.endTime,
            t.checkin_start,
            t.checkin_end,
            t.checkout_start,
            t.checkout_end,
            t.lunchout_start,
            t.lunchout_end,
            t.lunchin_start,
            t.lunchin_end
        FROM
            employee e
        INNER JOIN
            iclock_transaction it ON e.emp_code = it.emp_code AND DATE(it.punch_time) = ?
        LEFT JOIN
            shift s ON e.shift = s.shiftType
        LEFT JOIN
            time t ON s.shiftType = t.shiftType
    `;

    db.query(sql, [currentDate], (err, result) => {
        if (err) {
            console.error('Error fetching data:', err);
            res.status(500).json({ error: 'Error fetching data' });
        } else {
            res.json(result);
        }
    });
});
cron.schedule('*/1 * * * *', async () => {
    console.log('Automated task started at', new Date());

    try {
        const entries = await fetchUnitEntriesGeneral();

        const groupedEntries = {};
        for (const entry of entries) {
            const empCode = entry['emp_code'].toString();
            if (!groupedEntries.hasOwnProperty(empCode)) {
                groupedEntries[empCode] = [];
            }
            groupedEntries[empCode].push(entry);
        }

        const insertFutures = [];

        for (const empEntry of Object.entries(groupedEntries)) {
            const empData = empEntry[1];

            // Define moment objects for time ranges
            const checkinStart = moment(empData[0]['checkin_start'], 'HH:mm:ss');
            const checkinEnd = moment(empData[0]['checkin_end'], 'HH:mm:ss');
            const checkoutStart = moment(empData[0]['checkout_start'], 'HH:mm:ss');
            const checkoutEnd = moment(empData[0]['checkout_end'], 'HH:mm:ss');
            const shiftStartTime = moment(empData[0]['startTime'], 'HH:mm:ss'); // Fetch startTime from shift data
            const shiftEndTime = moment(empData[0]['endTime'], 'HH:mm:ss');// Assuming endTime is fetched from shift data
            const reqTimeMinutes = shiftEndTime.diff(shiftStartTime, 'minutes');

            const checkInTime = empData.length >= 1 ? moment(empData[0]['punch_time']) : null;
            const checkOutTime = empData.length >= 2 ? moment(empData[1]['punch_time']) : null;

            let remark = '';
            let lateCheckInMinutes = 0;
            let earlyCheckOutMinutes = 0;
            let actTimeMinutes = 0;

            // Calculate late check-in minutes
            if (checkInTime && checkInTime.isValid() && checkInTime.isAfter(checkinEnd)) {
                const difference = checkInTime.diff(checkinEnd, 'minutes');
                lateCheckInMinutes = difference;
            }

            // Calculate early check-out minutes
            if (checkOutTime && checkOutTime.isValid() && checkOutTime.isBefore(checkoutStart)) {
                const difference = checkoutStart.diff(checkOutTime, 'minutes');
                earlyCheckOutMinutes = difference;
            }

            if (checkInTime && checkOutTime && checkInTime.isValid() && checkOutTime.isValid()) {
                actTimeMinutes = checkOutTime.diff(checkInTime, 'minutes');
            }

            // Determine remark
            if (empData.length === 1) {
                remark = 'A';
            } else {
                remark = 'P';
            }

            // Calculate daily salary
            const monthlySalary = parseFloat(empData[0]['salary']);
            const currentMonth = moment().month() + 1; // current month (1-12)
            const currentYear = moment().year(); // current year
            const daysInMonth = moment(`${currentYear}-${currentMonth}`, 'YYYY-MM').daysInMonth();
            let dailySalary = monthlySalary / daysInMonth;

            // Custom rounding logic
            dailySalary = dailySalary < Math.ceil(dailySalary) - 0.50 ? Math.floor(dailySalary) : Math.ceil(dailySalary);

            // Prepare data for insertion
            console.log('checkInTime:', checkInTime ? checkInTime.format('HH:mm:ss') : 'null');
            console.log('checkOutTime:', checkOutTime ? checkOutTime.format('HH:mm:ss') : 'null');
            console.log('shiftEndTime:', shiftEndTime.format('HH:mm:ss'));
            console.log('lateCheckInMinutes:', lateCheckInMinutes);
            console.log('earlyCheckOutMinutes:', earlyCheckOutMinutes);
            console.log('reqTimeMinutes:', reqTimeMinutes);
            console.log('actTimeMinutes:', actTimeMinutes);
            console.log('dailySalary:', dailySalary);

            const dataToInsertcustomer = {
                "emp_code": empEntry[0],
                "first_name": empData[0]['first_name'].toString(),
                "monthly_salary": empData[0]['salary'].toString(),
                "salary": dailySalary, // Added daily salary
                'inDate': checkInTime ? checkInTime.format('YYYY-MM-DD') : moment().format('YYYY-MM-DD'),
                'shiftType': empData[0]['shiftType'],
                'check_in': checkInTime && checkInTime.isValid() ? checkInTime.format('HH:mm:ss') : '',
                'check_out': checkOutTime && checkOutTime.isValid() ? checkOutTime.format('HH:mm:ss') : '',
//                'check_in': checkInTime && (checkInTime.isBetween(checkinStart, checkinEnd) || checkInTime.isSameOrAfter(checkinStart)) ? checkInTime.format('HH:mm:ss') : '',
//                'check_out': checkOutTime && checkOutTime.isValid() ? checkOutTime.format('HH:mm:ss') : '',
                'latecheck_in': lateCheckInMinutes,
                'earlycheck_out': earlyCheckOutMinutes,
                'act_time': actTimeMinutes,
                'req_time': reqTimeMinutes,
                'remark': remark,
            };

            insertFutures.push(insertDatacustomer(dataToInsertcustomer));
        }

        await Promise.all(insertFutures);
        console.log('All data inserted successfully');
    } catch (error) {
        console.error('Error inserting/updating data:', error);
    }

    console.log('Automated task completed at', new Date());
});

//end General auto save


app.get('/attendance-summary', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in YYYY-MM-DD format

  const queryTotalEmployees = `SELECT COUNT(*) AS totalEmployees FROM employee`;
  const queryPresent = `SELECT COUNT(DISTINCT emp_code) AS present FROM attendance WHERE inDate = ?`;
  const queryAbsent = `SELECT COUNT(*) AS absent FROM employee WHERE emp_code NOT IN (SELECT DISTINCT emp_code FROM attendance WHERE inDate = ?)`;

  db.query(queryTotalEmployees, (err, totalEmployeesResult) => {
    if (err) {
      console.log('Error in queryTotalEmployees:', err);
      return res.status(500).json({ error: err });
    }
    db.query(queryPresent, [currentDate], (err, presentResult) => {
      if (err) {
        console.log('Error in queryPresent:', err);
        return res.status(500).json({ error: err });
      }
      db.query(queryAbsent, [currentDate], (err, absentResult) => {
        if (err) {
          console.log('Error in queryAbsent:', err);
          return res.status(500).json({ error: err });
        }
        console.log('Results:', {
          totalEmployees: totalEmployeesResult[0].totalEmployees,
          present: presentResult[0].present,
          absent: absentResult[0].absent
        });
        res.json({
          totalEmployees: totalEmployeesResult[0].totalEmployees,
          present: presentResult[0].present,
          absent: absentResult[0].absent
        });
      });
    });
  });
});
// Gowtham WorkStart
app.get('/present-employees', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in YYYY-MM-DD format

  const queryPresent = `
    SELECT e.emp_code, e.first_name, e.empMobile
    FROM employee e
    JOIN attendance a ON e.emp_code = a.emp_code
    WHERE a.inDate = ?`;

  db.query(queryPresent, [currentDate], (err, result) => {
    if (err) {
      return res.status(500).json({ error: err });
    }
    res.json(result);
  });
});
app.get('/absent-employees', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in YYYY-MM-DD format

  const queryAbsent = `
    SELECT e.emp_code, e.first_name, e.empMobile
    FROM employee e
    WHERE e.emp_code NOT IN (
      SELECT emp_code
      FROM attendance
      WHERE inDate = ?)`;

  db.query(queryAbsent, [currentDate], (err, result) => {
    if (err) {
      return res.status(500).json({ error: err });
    }
    res.json(result);
  });
});
app.get('/attendance-summary', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in YYYY-MM-DD format

  const queryTotalEmployees = `SELECT COUNT(*) AS totalEmployees FROM employee`;
  const queryPresent = `SELECT COUNT(DISTINCT emp_code) AS present FROM attendance WHERE inDate = ?`;
  const queryAbsent = `SELECT COUNT(*) AS absent FROM employee WHERE emp_code NOT IN (SELECT DISTINCT emp_code FROM attendance WHERE inDate = ?)`;

  db.query(queryTotalEmployees, (err, totalEmployeesResult) => {
    if (err) {
      console.log('Error in queryTotalEmployees:', err);
      return res.status(500).json({ error: err });
    }
    db.query(queryPresent, [currentDate], (err, presentResult) => {
      if (err) {
        console.log('Error in queryPresent:', err);
        return res.status(500).json({ error: err });
      }
      db.query(queryAbsent, [currentDate], (err, absentResult) => {
        if (err) {
          console.log('Error in queryAbsent:', err);
          return res.status(500).json({ error: err });
        }
        console.log('Results:', {
          totalEmployees: totalEmployeesResult[0].totalEmployees,
          present: presentResult[0].present,
          absent: absentResult[0].absent
        });
        res.json({
          totalEmployees: totalEmployeesResult[0].totalEmployees,
          present: presentResult[0].present,
          absent: absentResult[0].absent
        });
      });
    });
  });
});
app.get('/get_attendance_overall', (req, res) => {
  const { fromDate, toDate, emp_code, first_name, shiftType } = req.query;

  let sqlAttendanceDates = 'SELECT DISTINCT inDate FROM attendance WHERE 1=1';
  let sqlAttendance = 'SELECT * FROM attendance WHERE 1=1';
  let sqlEmployees = 'SELECT * FROM employee WHERE 1=1';
  const paramsAttendance = [];
  const paramsEmployees = [];

  if (fromDate) {
    sqlAttendanceDates += ' AND inDate >= ?';
    sqlAttendance += ' AND inDate >= ?';
    paramsAttendance.push(fromDate);
  }
  if (toDate) {
    sqlAttendanceDates += ' AND inDate <= ?';
    sqlAttendance += ' AND inDate <= ?';
    paramsAttendance.push(toDate);
  }
  if (shiftType) {
    sqlAttendance += ' AND shiftType = ?';
    paramsAttendance.push(shiftType);
  }

  // Filtering employees based on emp_code and first_name
  if (emp_code) {
    sqlEmployees += ' AND emp_code = ?';
    paramsEmployees.push(emp_code);
  }
  if (first_name) {
    sqlEmployees += ' AND first_name LIKE ?';
    paramsEmployees.push(`%${first_name}%`);
  }

  db.query(sqlEmployees, paramsEmployees, (errEmployees, resultEmployees) => {
    if (errEmployees) {
      console.error('Error fetching employee data:', errEmployees);
      res.status(500).json({ error: 'Error fetching employee data' });
    } else {
      db.query(sqlAttendanceDates, paramsAttendance, (errDates, resultDates) => {
        if (errDates) {
          console.error('Error fetching attendance dates:', errDates);
          res.status(500).json({ error: 'Error fetching attendance dates' });
        } else {
          const uniqueDates = resultDates.map(row => row.inDate);

          db.query(sqlAttendance, paramsAttendance, (errAttendance, resultAttendance) => {
            if (errAttendance) {
              console.error('Error fetching attendance data:', errAttendance);
              res.status(500).json({ error: 'Error fetching attendance data' });
            } else {
              const attendanceMap = new Map();
              resultAttendance.forEach(row => {
                const key = `${row.emp_code}-${row.inDate}`;
                attendanceMap.set(key, row);
              });

              const combinedData = [];

              uniqueDates.forEach(date => {
                resultEmployees.forEach(emp => {
                  const key = `${emp.emp_code}-${date}`;
                  const attendance = attendanceMap.get(key);
                  if (!shiftType || (attendance && attendance.shiftType === shiftType)) {
                    combinedData.push({
                      ...emp,
                      inDate: date,
                      check_in: attendance ? attendance.check_in : '',
                      check_out: attendance ? attendance.check_out : '',
                      act_time: attendance ? attendance.act_time : '',
                      shiftType: attendance ? attendance.shiftType : '',
                      latecheck_in: attendance ? attendance.latecheck_in : '',
                      earlycheck_out: attendance ? attendance.earlycheck_out : '',
                      req_time: attendance ? attendance.req_time : '',
                      remark: attendance ? 'Present' : 'Absent'
                    });
                  }
                });
              });

              res.status(200).json(combinedData);
            }
          });
        }
      });
    }
  });
});
app.get('/get_employee', (req, res) => {
  const sql = 'SELECT * from employee'; // Assuming id is the primary key of the attendance table
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});
/// Gowtham Work End
app.get('/get_shift_type', (req, res) => {
  const sql = 'SELECT shiftType FROM shift'; // Only select shiftType
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});
app.put('/employee/update/:emp_code', (req, res) => {
  const emp_code = req.params.emp_code;
  const employeeData = req.body;

  // Ensure that 'gender' is provided and not null
  if (employeeData.gender === undefined || employeeData.gender === null) {
    return res.status(400).send('Gender cannot be null');
  }
  console.log('Values before update:', employeeData);
  const sql = 'UPDATE employee SET ? WHERE emp_code=?';
  const values = [{...employeeData}, emp_code];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating employee:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Employee updated successfully');
    }
  });
});
app.get('/getemployeename', (req, res) => {
  const sql = 'select * from employee'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/getemployee', (req, res) => {
  const sql = 'select * from personnel_employee'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/employeebyname/:emp_code', (req, res) => {
  const empID = req.params.empID;

  const query = 'SELECT * FROM employee WHERE emp_code = ?';

  db.query(query, [empID], (err, results) => {
    if (err) {
      console.error('Error fetching employee details:', err);
      res.status(500).send('Error fetching employee details');
      return;
    }
    if (results.length === 0) {
      res.status(404).send('Employee not found');
      return;
    }

    res.json(results[0]);
  });
});
app.post('/employee_entry', (req, res) => {
  const { dataToInsertcustomer } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO employee SET ?'; // Modify to your table name

  db.query(sql, dataToInsertcustomer, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/getemployeid', (req, res) => {
  const sql = 'select * from employee'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/checking_empid', (req, res) => {
  const sql = 'select * from employee'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.get('/get_cumulative_salary', (req, res) => {
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;
  const shiftType = req.query.shiftType;

  const sql = `
    SELECT
      emp_code,
      monthly_salary,
      salary AS perDaySalary,
      CONCAT(first_name, '(', emp_code, ')') AS employee,
      MIN(inDate) AS from_date,
      MAX(inDate) AS to_date,
      a.shiftType AS shift_type,
      COUNT(DISTINCT DATE(inDate)) AS no_of_work_days,
      SUM(req_time) AS total_req_time,
      SUM(act_time) AS total_act_time,
      SUM(salary) AS total_salary,
      ROUND(SUM(req_time) - SUM(act_time), 2) AS total_late,
      CASE
        WHEN monthly_salary > SUM(salary) THEN monthly_salary - SUM(salary)
        ELSE 0
      END AS deduction_salary
    FROM
      attendance AS a
    WHERE
      inDate BETWEEN ? AND ?
      AND a.shiftType = ?
    GROUP BY
      emp_code,
      first_name,
      a.shiftType,
      monthly_salary,
      salary
  `;

  console.log('Executing query:', sql);
  console.log('With parameters:', [fromDate, toDate, shiftType]);

  db.query(sql, [fromDate, toDate, shiftType], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully:', result);
      res.status(200).json(result);
    }
  });
});
app.get('/get_individual_salary', (req, res) => {
   const sql = 'select * from attendance'; // Modify to your table name
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});
app.get('/employee_get_report', (req, res) => {
  const sql = 'SELECT * FROM employee'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/update_status', (req, res) => {
  const emp_code = req.body.emp_code;
  const Status = req.body.Status;
  const sql = `UPDATE employee SET Status = ? WHERE emp_code = ?`;
  db.query(sql, [Status, emp_code], (err, result) => {
    if (err) {
      console.error('Error updating employee status:', err);
      res.status(500).json({ error: 'Error updating employee status' });
    } else {
      console.log('Employee status updated successfully');
      res.status(200).json({ message: 'Employee status updated successfully' });
    }
  });
});
app.delete('/Employee_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM employee WHERE id = ?';
  const values = [id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});
app.post('/update_status', (req, res) => {
  const emp_code = req.body.emp_code;
  const Status = req.body.Status;
  const sql = `UPDATE employee SET Status = ? WHERE emp_code = ?`;
  db.query(sql, [Status, emp_code], (err, result) => {
    if (err) {
      console.error('Error updating employee status:', err);
      res.status(500).json({ error: 'Error updating employee status' });
    } else {
      console.log('Employee status updated successfully');
      res.status(200).json({ message: 'Employee status updated successfully' });
    }
  });
});
app.post('/update_status2', (req, res) => {
  const emp_code = req.body.emp_code;
  const Status = req.body.Status;
  const sql = `UPDATE employee SET Status = ? WHERE emp_code = ?`;
  db.query(sql, [Status, emp_code], (err, result) => {
    if (err) {
      console.error('Error updating employee status:', err);
      res.status(500).json({ error: 'Error updating employee status' });
    } else {
      console.log('Employee status updated successfully');
      res.status(200).json({ message: 'Employee status updated successfully' });
    }
  });
});
app.get('/fetch_company_details', (req, res) => {
  const id = req.query.id;
  const query = `SELECT companyName, address, contact FROM company WHERE id = ?`;

  db.query(query, [id], (error, results) => {
    if (error) {
      console.error(error);
      res.status(500).send('Error fetching company data');
    }
    else {
      if (results.length > 0) {
        res.status(200).json(results[0]);
      } else {
        res.status(404).send('Company not found');
      }
    }
  });
});

app.post('/shift_insert_tvs', (req, res) => {
  const { shiftType, startTime, endTime, checkin_start, checkin_end, checkout_start, checkout_end } = req.body;

  // Check if shiftType already exists in time table
  const checkSql = 'SELECT * FROM time WHERE shiftType = ?';
  db.query(checkSql, [shiftType], (err, results) => {
    if (err) {
      console.error('Error executing query:', err);
      res.status(500).send('Error checking shift in database');
      return;
    }

    if (results.length > 0) {
      // ShiftType already exists in time table, insert only into shift table
      const sqlShift = 'INSERT INTO shift (shiftType, startTime, endTime) VALUES (?, ?, ?)';
      db.query(sqlShift, [shiftType, startTime, endTime], (err, result) => {
        if (err) {
          console.error('Error inserting shift:', err);
          res.status(500).send('Error inserting shift into database');
          return;
        }

        console.log('Shift added:', result);

        // Respond with success for shift insertion
        res.status(200).json({
          message: 'Shift added ',
          shiftId: result.insertId,
          shiftType,
          startTime,
          endTime,
        });
      });
    } else {
      // ShiftType does not exist in time table, proceed to insert into both tables
      const sqlShift = 'INSERT INTO shift (shiftType, startTime, endTime) VALUES (?, ?, ?)';
      db.query(sqlShift, [shiftType, startTime, endTime], (err, result) => {
        if (err) {
          console.error('Error inserting shift:', err);
          res.status(500).send('Error inserting shift into database');
          return;
        }

        console.log('Shift added:', result);

        // Insert into time table
        const sqlTime = 'INSERT INTO time (shiftType, checkin_start, checkin_end, checkout_start, checkout_end) VALUES (?, ?, ?, ?, ?)';
        const values = [shiftType, checkin_start, checkin_end, checkout_start, checkout_end];
        db.query(sqlTime, values, (err, result) => {
          if (err) {
            console.error('Error inserting time:', err);
            res.status(500).send('Error inserting time into database');
            return;
          }

          console.log('Time added:', result);

          // Respond with success for both shift and time insertion
          res.status(200).json({
            message: 'Shift and Time added',
            shiftId: result.insertId,
            shiftType,
            startTime,
            endTime,
            timeId: result.insertId,
            checkin_start,
            checkin_end,
            checkout_start,
            checkout_end,
          });
        });
      });
    }
  });
});
app.get('/shift_tvs', (req, res) => {
  const sql = 'select * from shift'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.delete('/shift_tvs_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM shift WHERE id = ?';
  const values = [id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});
app.get('/timing', (req, res) => {
  const { shiftType } = req.query;
  const sql = 'SELECT * FROM time WHERE shiftType = ?';
  const values = [shiftType];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/company_profile',(req,res)=>{
  const {profileData}= req.body;
  const sql='INSERT INTO company set?';
  console.log('Sql Query:',sql);
  db.query(sql,[profileData],(err,result)=>{
  if(err){
  console.err('Failed to insert',err);
  res.status(500).json({message:'failed to insert data'});
  }
  else{
  console.log('Data inserted successfully');
  res.status(200).json({message:'data inserted successfully'});
  }
  })
});
app.get('/company_fetch', (req, res) => {
  const sql = 'SELECT * FROM company';
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});
app.get('/fetch_company_duplicate', (req, res) => {
  const sql = 'SELECT uid FROM company'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/company_update', async (req, res) => {
  const { uid, companyName, address, contact, mailId, gstNo, tinNo, cstNo, bankName, accNo, branch, ifscCode } = req.body;
  const sql = 'UPDATE company SET uid = ?, companyName = ?, address = ?, contact = ?, mailId = ?, gstNo = ?, tinNo = ?, cstNo = ?, bankName = ?, accNo = ?, branch = ?, ifscCode = ? WHERE uid = ?'; // Modified query
  const values = [uid, companyName, address, contact, mailId, gstNo, tinNo, cstNo, bankName, accNo, branch, ifscCode, uid]; // Modified values array

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating purchase entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Purchase entry updated successfully');
    }
  });
});


// Starting the server
app.listen(app.get('port'), () => {
  console.log('Server on port', app.get('port'));
});