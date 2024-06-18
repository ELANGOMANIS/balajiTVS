
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



//end morning auto save
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
        LEFT JOIN
            iclock_transaction it ON e.emp_code = it.emp_code
        LEFT JOIN
            shift s ON e.shift = s.shiftType
        LEFT JOIN
            time t ON s.shiftType = t.shiftType
        WHERE
            (DATE(it.punch_time) = ? OR DATE(it.punch_time) IS NULL)
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

            // Prepare data for insertion
            console.log('checkInTime:', checkInTime ? checkInTime.format('HH:mm:ss') : 'null');
            console.log('checkOutTime:', checkOutTime ? checkOutTime.format('HH:mm:ss') : 'null');
            console.log('shiftEndTime:', shiftEndTime.format('HH:mm:ss'));
            console.log('lateCheckInMinutes:', lateCheckInMinutes);
            console.log('earlyCheckOutMinutes:', earlyCheckOutMinutes);
            console.log('reqTimeMinutes:', reqTimeMinutes);
            console.log('actTimeMinutes:', actTimeMinutes);


            const dataToInsertcustomer = {
                "emp_code": empEntry[0],
                "first_name": empData[0]['first_name'].toString(),
                "salary": empData[0]['salary'].toString(),
                "salaryType": empData[0]['salaryType'].toString(),
                'inDate': moment(empData[0]['punch_time']).format('YYYY-MM-DD'),
                'shiftType': empData[0]['shiftType'],
                'check_in': checkInTime && (checkInTime.isBetween(checkinStart, checkinEnd) || checkInTime.isSameOrAfter(checkinStart)) ? checkInTime.format('HH:mm:ss') : '',
                'check_out': checkOutTime && checkOutTime.isValid() ? checkOutTime.format('HH:mm:ss') : '',
                'latecheck_in': lateCheckInMinutes,
                'earlycheck_out': earlyCheckOutMinutes,
                'act_time': actTimeMinutes,
                'req_time':reqTimeMinutes,
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


//24/11/2023
app.get('/checkorderNo_Customer_order', (req, res) => {
  const sql = 'select * from purchase_order'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//raja-25-11-2023

app.get('/getorderno', (req, res) => {
  const sql = 'SELECT * FROM sales order by orderNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});




app.get('/checkinvoice_fordc', (req, res) => {
  const sql = 'select * from dc'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/checkorderNo', (req, res) => {
  const sql = 'select * from sales'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/get_purchase_orderitem', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT itemGroup,itemName,qty FROM purchase_order WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/getorderdetails', (req, res) => {
  const sql = 'select * from purchase_order'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/get_order_details', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT p.custName,c.custAddress,c.custMobile,c.gstin,
  p.deliveryType,p.deliveryDate FROM purchase_order p
                 LEFT JOIN customer c ON p.custCode=c.custCode
                 WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/get_custdetails_order', (req, res) => {
   const sql = `select  p.orderNo,  p.custCode,  p.custName, c.custAddress,c.custMobile, c.gstin
   from purchase_order p
   left join customer c on p.custCode = c.custCode
   `; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});//23//11/2023

app.put('/purchase_order_update/:orderNo', (req, res) => {
  const { orderNo } = req.params;
  const { custCode,custName,deliveryDate,deliveryType,itemName,itemGroup,qty,totQty,modifyDate } = req.body;

  const sql = 'UPDATE purchase_order SET custName = ?, custCode = ?,deliveryDate = ?, deliveryType = ?, itemGroup = ?, itemName = ?,qty = ?, totQty = ?,modifyDate = ? WHERE orderNo = ?';
  const values = [custCode,custName,deliveryDate,deliveryType,itemName,itemGroup,qty,totQty,modifyDate, orderNo];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.get('/getcustomer_purchase_order', (req, res) => {
  const sql = 'select * from purchase_order ORDER BY orderNo DESC '; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.delete('/getcustomer_purchase_order', (req, res) => {
  const { orderNo } = req.params;

  const sql = 'DELETE FROM purchase_order WHERE orderNo = ?';
  const values = [orderNo];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});
app.post('/purchaseorder_update', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO purchase_order SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});



//raja
/*
app.get('/checkorderNo', (req, res) => {
  const sql = 'select * from purchase_order'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
*/

app.post('/DC', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO dc SET ?';// Modify to your table name

  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/dc_entries', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});


app.get('/getCustomer', (req, res) => {
  const sql = 'select * from customer'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getSales', (req, res) => {
  const sql = 'select * from sales ORDER BY invoiceNo DESC'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getSales_balanceSheet', (req, res) => {
  const sql = 'select * from sales ORDER BY invoiceNo DESC'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/get_sales_name_data', (req, res) => {
  const sql =`SELECT DISTINCT po.orderNo
              FROM pending_sales_order po
              LEFT JOIN sales s ON po.orderNo = s.individualOrderNo
              WHERE s.individualOrderNo IS NULL;
             `;

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


app.get('/get_pending_name_data', (req, res) => {
  const sql = `SELECT po.pendingOrderNo, po.checkOrderNo
               FROM pending_report po
               WHERE NOT EXISTS (
                 SELECT 1
                 FROM sales s
                 WHERE FIND_IN_SET(po.pendingOrderNo, REPLACE(s.orderNo, ' ', '')) > 0
               );`;

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
app.post('/fetchStock_available', (req, res) => {
  const { itemName } = req.body;
  const query = `SELECT itemGroup FROM stock WHERE itemName = ?`;

  db.query(query, [itemName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }
    if (results.length > 0) {
      res.json({ itemGroup: results[0].itemGroup });
    } else {
      res.json({ itemGroup: '' }); // Return an empty string if no match found
    }
  });
});

app.get('/get_stock_quantity', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;

      const query = 'SELECT qty FROM stock WHERE itemGroup = ? AND itemName = ?';

  db.query(query, [itemGroup, itemName], (err, result) => {
    if (err) {
      console.log('Error executing MySQL query:', err);
      res.status(500).send('Internal Server Error');
    } else {
      if (result.length > 0) {
        const stockQuantity = result[0].qty;
        res.status(200).json({ qty: stockQuantity });
      } else {
        res.status(404).send('Stock not found for the specified itemGroup and itemName');
      }
    }
  });
});

//stock to sales
app.put('/stock/update/:itemGroup/:itemName', (req, res) => {
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const { totalconesIncrement } = req.body;
  const { qtyIncrement } = req.body;

  console.log('Values before update:', req.body);
  const sql = 'UPDATE stock SET  qty=qty+?,totalcones=totalcones+? WHERE itemGroup=? AND itemName=? ';
  const values = [qtyIncrement, totalconesIncrement, itemGroup, itemName];

//  const sql = 'UPDATE production_entry SET saleInvNo=? WHERE itemGroup=? AND itemName=?';
 // const values = [saleInvNo, itemGroup, itemName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Production updated successfully');
    }
  });
});

app.post('/sales_to_update_Stock', async (req, res) => {
  const { produce_pack, produce_totalcones, qty, totalcones, itemGroup, itemName, date } = req.body;
  // Check if a record with the specified GSM value already exists
  const checkSql = 'SELECT * FROM stock WHERE itemGroup = ? AND itemName = ?';
  db.query(checkSql, [itemGroup, itemName], (checkErr, checkResult) => {
    if (checkErr) {
      console.error('Error checking if record exists:', checkErr);
      res.status(500).send('Internal Server Error');
    } else {
      if (checkResult.length > 0) {
      const date = new Date().toISOString().slice(0, 19).replace('T', ' ');
        // Update the existing record
        const updateSql = 'UPDATE stock SET produce_pack = produce_pack + ?, produce_totalcones = produce_totalcones + ?, qty = qty + ?, totalcones = totalcones + ?, date = ? WHERE itemGroup = ? AND itemName = ?';
        const updateValues = [produce_pack, produce_totalcones, qty, totalcones, date, itemGroup, itemName];
        db.query(updateSql, updateValues, (updateErr, updateResult) => {
          if (updateErr) {
            console.error('Error updating entry:', updateErr);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('Entry updated successfully');
          }
        });
      } else {
            const date = new Date().toISOString().slice(0, 19).replace('T', ' ');
        // Insert a new record
        const insertSql = 'INSERT INTO stock (produce_pack, produce_totalcones, qty, totalcones, itemGroup, itemName, date) VALUES (?, ?, ?, ?, ?, ?, ?)';
        const insertValues = [produce_pack, produce_totalcones, qty, totalcones, itemGroup, itemName, date];
        db.query(insertSql, insertValues, (insertErr, insertResult) => {
          if (insertErr) {
            console.error('Error inserting new entry:', insertErr);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('New entry inserted successfully');
          }
        });
      }
    }
  });
});
/*app.post('/sales_to_update_Stock', async (req, res) => {
  const { itemGroup, itemName, qty, totalcones } = req.body;
  const selectSql = 'SELECT * FROM stock WHERE itemGroup = ? AND itemName = ?';
  const selectValues = [itemGroup, itemName];

  db.query(selectSql, selectValues, (selectErr, selectResult) => {
    if (selectErr) {
      console.error('Error selecting from stock:', selectErr);
      res.status(500).send('Internal Server Error');
      return;
    }

    if (selectResult.length === 0) {
      // If no rows found, insert new row
     const currentDate = new Date().toISOString().slice(0, 19).replace('T', ' '); // Get current date and time
     const insertSql = 'INSERT INTO stock (itemGroup, itemName, qty, totalcones, date) VALUES (?, ?, ?, ?, ?)';
     const insertValues = [itemGroup, itemName, qty, totalcones, currentDate];

      db.query(insertSql, insertValues, (insertErr, insertResult) => {
        if (insertErr) {
          console.error('Error inserting into stock:', insertErr);
          res.status(500).send('Internal Server Error');
          return;
        }
        res.send('New item inserted into stock successfully');
      });
    } else {
      // If rows found, update existing row
      const updateSql = 'UPDATE stock SET qty = qty + ?, totalcones = totalcones + ? WHERE itemGroup = ? AND itemName = ?';
      const updateValues = [qty, totalcones, itemGroup, itemName];

      db.query(updateSql, updateValues, (updateErr, updateResult) => {
        if (updateErr) {
          console.error('Error updating stock:', updateErr);
          res.status(500).send('Internal Server Error');
          return;
        }
        res.send('Existing item in stock updated successfully');
      });
    }
  });
});*/

/*
app.post('/sales_to_update_Stock', async (req, res) => {
  const { itemGroup, itemName, qty } = req.body;
  const sql = 'UPDATE stock SET qty=qty-? WHERE itemGroup=? AND itemName=? ';
  const values = [qty, itemGroup, itemName,];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});
*/

//production decrease in sales
app.post('/sales_to_update_Production', async (req, res) => {
  const { itemGroup, itemName, invoiceNo, qty } = req.body;
  const sql = 'UPDATE production_entry SET invoiceNo=?, qty=qty-? WHERE itemGroup=? AND itemName=?';
  const values = [invoiceNo, qty, itemGroup, itemName]; // <-- Corrected here

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error'); // Handle the error with a response
    } else {
      res.send('production_entry updated successfully'); // Send a success response
    }
  });
});

//dc number
app.get('/getDcno', (req, res) => {
  const sql = 'SELECT * FROM dc order by dcNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//dc report
app.get('/getDC', (req, res) => {
  const sql = 'select * from dc'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//dc item report

app.get('/dc_item_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
//purchase edit
app.post('/add_MinusRawMaterial', async (req, res) => {
  const { prodCode, prodName, qty, unit, modifyDate, isIncrease } = req.body;

  let sql, values;

  if (isIncrease) {
    // Increase quantity
    sql = 'UPDATE raw_material SET qty = qty + ?, modifyDate = ? WHERE prodCode = ? AND prodName = ? AND unit = ?';
    values = [qty, modifyDate, prodCode, prodName, unit];
  } else {
    // Decrease quantity
    sql = 'UPDATE raw_material SET qty = qty - ?, modifyDate = ? WHERE prodCode = ? AND prodName = ? AND unit = ?';
    values = [qty, modifyDate, prodCode, prodName, unit];
  }

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
app.post('/Raw_material_entry_edit', (req, res) => {
  const { dataToInsertRaw2 } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO raw_material SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertRaw2], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});


app.get('/fetch_productcode_poNo_duplicate', (req, res) => {
  const sql = 'SELECT * FROM purchase';
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

app.post('/purchase_edit_new_update', (req, res) => {
  const { dataToInsertRaw } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO purchase SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertRaw], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/purchase_edit_new_update_gsm', (req, res) => {
  const { dataToInsertRawGsm } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO purchase SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertRawGsm], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/purchase_gsm_edit_update', async (req, res) =>    {
  const { purchaseDate, invoiceNo, supCode, supName, supMobile, supAddress, pincode, payType, prodCode, prodName, unit, sNo, totalWeight, rate, amt, gst, amtGST, total, grandTotal, extraCharge, discount, poNo } = req.body;

  if (!poNo || !prodCode) {
    res.status(400).send('Both poNo and prodCode are required for the update');
    return;
  }

  const sql = 'UPDATE purchase SET purchaseDate = ?, invoiceNo = ?, supCode = ?, supName = ?, supMobile = ?, supAddress = ?, pincode = ?, payType = ?, prodCode = ?, prodName = ?, unit = ?, sNo = ?, totalWeight = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ?, extraCharge = ?, discount = ? WHERE poNo = ? AND prodCode = ?';
  const values = [purchaseDate, invoiceNo, supCode, supName, supMobile, supAddress, pincode, payType, prodCode, prodName, unit, sNo, totalWeight, rate, amt, gst, amtGST, total, grandTotal, extraCharge, discount, poNo, prodCode];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating purchase entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Purchase entry updated successfully');
    }
  });
});
app.post('/purchase_edit_update', async (req, res) => {
  const { purchaseDate, invoiceNo, supCode, supName, supMobile, supAddress, pincode, payType, prodCode, prodName, unit, qty, rate, amt, gst, amtGST, total, grandTotal, extraCharge, discount, poNo } = req.body;

  if (!poNo || !prodCode) {
    res.status(400).send('Both poNo and prodCode are required for the update');
    return;
  }

  const sql = 'UPDATE purchase SET purchaseDate = ?, invoiceNo = ?, supCode = ?, supName = ?, supMobile = ?, supAddress = ?, pincode = ?, payType = ?, prodCode = ?, prodName = ?, unit = ?, qty = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ?, extraCharge = ?, discount = ? WHERE poNo = ? AND prodCode = ?';
  const values = [purchaseDate, invoiceNo, supCode, supName, supMobile, supAddress, pincode, payType, prodCode, prodName, unit, qty, rate, amt, gst, amtGST, total, grandTotal, extraCharge, discount, poNo, prodCode];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating purchase entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Purchase entry updated successfully');
    }
  });
});
app.get('/fetch_purchase_datas', (req, res) => {
  const sql = 'SELECT * FROM purchase ORDER BY poNo DESC';
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
app.get('/fetch_purchase_datas_invoice', (req, res) => {
  const sql = 'SELECT * FROM purchase ORDER BY invoiceNo DESC';
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
/*
app.get('/get_purchase_items', (req, res) => {
  const poNo = req.query.poNo;
  const invoiceNo = req.query.invoiceNo;

  let sql;
  let values;

  if (poNo) {
    sql = `SELECT * FROM purchase WHERE poNo = ?`;
    values = [poNo];
  } else if (invoiceNo) {
    sql = `SELECT * FROM purchase WHERE invoiceNo = ?`;
    values = [invoiceNo];
  } else {
    res.status(400).send('Missing poNo or invoiceNo parameter');
    return;
  }

  db.query(sql, values, (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
*/

//purchase order entry
app.post('/purchaseorder_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO purchase_order SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//pending sale order entry 30/04
app.post('/pending_sale_order', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO pending_sales_order SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
//
//05-04-2024 bhuvi
app.get('/item_group_get', (req, res) => {
  const sql = 'select * from item'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.put('/dummy_production_qty_increament/update/:machineName/:itemGroup/:itemName/:date', (req, res) => {
  const machineName = req.params.machineName;
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const date = req.params.date;
  const { totalconesIncrement } = req.body;
  const { qtyIncrement } = req.body;


  console.log('Values before update Production:', req.body);

  const sql = 'UPDATE production_entry SET qty = CAST(qty AS SIGNED)  + ?, totalcones = CAST(totalcones AS SIGNED)  + ? WHERE machineName = ? AND itemGroup = ? AND itemName = ? AND date = ?';
  const values = [totalconesIncrement, qtyIncrement, machineName, itemGroup, itemName, date];

  console.log('SQL Query:', sql);
  console.log('SQL Values:', values);

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      console.log('Production updated successfully');
      res.send('Production updated successfully');
    }
  });
});

/*
app.put('/dummy_production_qty_increament/update/:machineName/:itemGroup/:itemName/:date', (req, res) => {
  const machineName = req.params.machineName;
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const date = req.params.date;
  const { qtyIncrement } = req.body;

  console.log('Values before update Production:', req.body);
  const sql = 'UPDATE production_entry SET  qty=qty+? WHERE machineName =? AND itemGroup=? AND itemName=? And date=?';
  const values = [qtyIncrement,machineName, itemGroup, itemName,date];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Production updated successfully');
    }
  });
});
*/

app.get('/get_unit_by_iG_iN', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;
//  const size = req.query.size;
//  const color = req.query.color;

  const sql = 'SELECT unit FROM item WHERE itemGroup = ? AND itemName = ?';

  // Logging parameters for debugging
  console.log('itemGroup:', itemGroup);
  console.log('itemName:', itemName);
//  console.log('size:', size);
//  console.log('color:', color);

  db.query(sql, [itemGroup, itemName], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json({ unit: null });
    } else {
      res.json(result[0]);
    }
  });
});
app.get('/get_rate_by_iG_iN', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;
//  const size = req.query.size;
//  const color = req.query.color;

  const sql = 'SELECT rate FROM item WHERE itemGroup = ? AND itemName = ?';

  // Logging parameters for debugging
  console.log('itemGroup:', itemGroup);
  console.log('itemName:', itemName);
//  console.log('size:', size);
//  console.log('color:', color);

  db.query(sql, [itemGroup, itemName], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json({ unit: null });
    } else {
      res.json(result[0]);
    }
  });
});
app.get('/get_gst_by_iG_iN', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;
  const sql = 'SELECT gst FROM item WHERE itemGroup = ? AND itemName = ?';
  console.log('itemGroup:', itemGroup);
  console.log('itemName:', itemName);

  db.query(sql, [itemGroup, itemName], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json({ unit: null });
    } else {
      res.json(result[0]);
    }
  });
});

app.get('/getitemname_by_itemgroup', (req, res) => {
  const itemGroup = req.query.itemGroup;

  const sql = 'SELECT itemName FROM item WHERE itemGroup = ?';

  db.query(sql, [itemGroup], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

//csv file upload query
//csv file upload query
/*
app.post('/upload', upload.single('csvFile'), (req, res) => {
  const csvBuffer = req.file.buffer.toString(); // Convert the buffer to a string

  // Process the CSV data and perform database operations
  const records = [];

  // Parse CSV data
  csv({
    mapHeaders: ({ header }) => header.trim(),
  })
    .on('data', (row) => {
      // Assuming your CSV columns match the fields in the itemCreation table
      records.push(row);
    })
    .on('end', () => {
      // Insert or update records in the 'itemCreation' table
      records.forEach((record) => {
        connection.query(
          'INSERT INTO itemCreation (itemGroup, itemName, itemCode, unit,packSize, gst, rate, createddate, updatedDate) VALUES (?, ?,?, ?, ?, ?, ?, NOW(), NOW()) ON DUPLICATE KEY UPDATE itemGroup = VALUES(itemGroup), itemName = VALUES(itemName), itemCode = VALUES(itemCode), unit = VALUES(unit),packSize = VALUES(packSize), gst = VALUES(gst), rate = VALUES(rate), updatedDate = NOW()',
          [
            record.itemGroup,
            record.itemName,
            record.itemCode,
            record.unit,
            record.packSize,
            record.gst,
            record.rate,
          ],
          (err, results) => {
            if (err) {
              console.error('Error inserting or updating data in MySQL:', err);
            } else {
              console.log('Record inserted or updated in MySQL');
            }
          }
        );
      });

      res.status(200).send('CSV file uploaded and processed.');
    });

  // Pipe the CSV data into the parser
  const stream = require('stream');
  const csvStream = new stream.PassThrough();
  csvStream.end(Buffer.from(csvBuffer));
  csvStream.pipe(csv());
});
*/
app.post('/customer_entry', (req, res) => {
  const { dataToInsertcustomer } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO customer SET ?'; // Modify to your table name

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

app.post('/purchaseitem_entry', (req, res) => {
  const { dataToInsertorditem } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO purchaseord_item SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertorditem], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error Table inserting data:', err);
      res.status(500).json({ error: 'Error Table inserting data' });
    } else {
      console.log('Table Data inserted successfully');
      res.status(200).json({ message: 'Table Data inserted successfully' });
    }
  });
});

app.get('/getItem', (req, res) => {
  const sql = 'select * from item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getColor', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;

 const sql = 'SELECT color,size FROM item WHERE itemGroup = ? AND itemName = ?';

   db.query(sql, [itemGroup, itemName], (err, results) => {
     if (err) {
       console.error('Error fetching color and size:', err);
       res.status(500).json({ error: 'Error fetching color and size' });
     } else if (results.length > 0) {
       const color = results[0].color;
       const size = results[0].size;
       res.status(200).json({ color, size });
     } else {
       res.status(404).json({ error: 'Color and size not found' });
     }
   });
 });



app.get('/custdetail', (req, res) => {
  const sql = 'SELECT * FROM customer'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/customerdetails', (req, res) => {
  const sql = 'SELECT * FROM customer'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/unitdetail', (req, res) => {
  const sql = 'SELECT * FROM item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getpurchaseordeitem', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT orderNo FROM purchaseord_item WHERE totQty = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

//purchase viwe
app.get('/customer_view', (req, res) => {
  const custCode = req.query.custCode;
  console.log('Received custCode:', custCode); // Add this line
  const sql = `SELECT * FROM customer WHERE custCode = ?`;
  db.query(sql, [custCode], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/purchase_item_view', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT * FROM purchase_order WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/pending_item_view', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT * FROM pending_sales_order WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});


app.get('/getcustomerdetails', (req, res) => {
  const customerCode = req.query.customerCode; // Get customer code from query parameter
  let sql = 'SELECT * FROM customer';

  if (customerCode) {
    // If customer code is provided, add a WHERE clause to filter by customer code
    sql += ` WHERE custCode = '${custCode}'`;
  }

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//purchase report
app.get('/getpurchaseorder', (req, res) => {
  const sql = 'select * from purchase_order'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getpurchasedetails', (req, res) => {
  const sql = 'select * from customer'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/purchaseorder_item_view', (req, res) => {
  const quotNo = req.query.orderNo;

  const sql = `SELECT * FROM purchase_order WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/existingcustCode', (req, res) => {
  const orderNo = req.query.quotNo;

  const sql = 'SELECT * FROM customer WHERE custCode NOT LIKE ?';

  db.query(sql, [`%${custCode}%`], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
//quation
app.post('/quotation', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO quotation SET ?'; // Modify to your table name
  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/quotationNo', (req, res) => {
  const sql = 'SELECT * FROM quotation order by quotNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.get('/quotation_entry', (req, res) => {
  const sql = 'SELECT * FROM quotation'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.get('/getQuotItem', (req, res) => {
  const sql = 'select * from item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/checkorderNo_forcustomerorder', (req, res) => {
  const sql = 'select * from purchase_order'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//customer
//customer update
/*app.put('/custupdate_update/:id', (req, res) => {
  const { id } = req.params;
  const { custName, custAddress, custMobile, gstin,modifyDate } = req.body;

  const sql = 'UPDATE customer SET custName = ?, custAddress = ?, custMobile = ?, gstin = ?,modifyDate = ? WHERE id = ?';
  const values = [custName, custAddress, custMobile, gstin,modifyDate, id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});*/

//report
app.get('/getcustomers', (req, res) => {
  const sql = 'select * from customer'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//delete
app.delete('/customerdelete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM customer WHERE id = ?';
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


//balancesheet
app.get('/balance_sheet_values_get_for_table', (req, res) => {
  try {
    const invoiceNosParam = req.query.invoiceNos;

    if (!invoiceNosParam) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order numbers not provided.' });
    }

    const invoiceNos = invoiceNosParam.split(',');

    const query = `
    SELECT distinct invoiceNo,grandTotal,custName,custCode FROM sales WHERE invoiceNo in (?)
    `;

    db.query(query, [invoiceNos], (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});


app.get('/kvbalance_sheet_values_get_for_table', (req, res) => {
  try {
    const kvinvoiceParam = req.query.kvinvoiceNos;

    if (!kvinvoiceParam) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order numbers not provided.' });
    }

    const kvinvoiceNos = kvinvoiceParam.split(',');

    const query = `
    SELECT distinct kvinvoice,grandTotal,custName,custCode FROM sales WHERE kvinvoice in (?)
    `;

    db.query(query, [kvinvoiceNos], (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});
app.get('/balance_sheet_values_purchase', (req, res) => {
  try {
    const invoiceNosParam = req.query.invoiceNos;

    if (!invoiceNosParam) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order numbers not provided.' });
    }

    const invoiceNos = invoiceNosParam.split(',');

    const query = `
    SELECT distinct invoiceNo,grandTotal,supName,supCode FROM purchase WHERE invoiceNo in (?)
    `;

    db.query(query, [invoiceNos], (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

/*app.get('/get_balancesheet_for_suggestion', (req, res) => {
  const sql = `
    SELECT DISTINCT s.invoiceNo
    FROM sales s
    LEFT JOIN balance_sheet b ON s.invoiceNo = b.individual_invoice
    WHERE b.individual_invoice IS NULL;
  `;

  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});*/


app.get('/get_balancesheet_for_suggestion', (req, res) => {
  const type = req.query.type;
  const sql = `
    SELECT DISTINCT
      s.${type}
    FROM
      sales s
    LEFT JOIN
      balance_sheet b
    ON
      s.invoiceNo = b.individual_invoice
    WHERE
      b.individual_invoice IS NULL
    AND
      s.company = ?;
  `;
  db.query(sql, [req.query.company], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});

app.get('/get_kvbalancesheet_for_suggestion', (req, res) => {
  const type = req.query.type;
  const sql = `
    SELECT DISTINCT
      s.${type}
    FROM
      sales s
    LEFT JOIN
      balance_sheet b
    ON
      s.kvinvoice = b.individual_invoice
    WHERE
      b.individual_invoice IS NULL
    AND
      s.company = ?;
  `;
  db.query(sql, [req.query.company], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});

app.get('/get_balancesheet_for_suggestion_purchase', (req, res) => {
  const sql = `
    SELECT DISTINCT p.invoiceNo
    FROM purchase p
    LEFT JOIN balance_sheet_purchase b ON p.invoiceNo = b.individual_invoice
    WHERE b.individual_invoice IS NULL;
  `;

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

app.post('/balanace_sheet', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO balance_sheet SET ?';// Modify to your table name

  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/balanace_sheet_purchase', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO balance_sheet_purchase SET ?';// Modify to your table name

  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/getBalance', (req, res) => {
  const company = req.query.company;
  const sql = `SELECT * FROM balance_sheet WHERE company = ?`;
  db.query(sql, [company], (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/KVgetBalance', (req, res) => {
  const company = req.query.company;
  const sql = `SELECT * FROM balance_sheet WHERE company = ?`;
  db.query(sql, [company], (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.get('/getPurchaseBalance', (req, res) => {
  const sql = 'select * from balance_sheet_purchase'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//machin Entry
app.post('/machine_entry', (req, res) => {
  const { dataToInsert } = req.body;

  const sql = 'INSERT INTO machine SET ?';

  db.query(sql, [dataToInsert], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//machine report
app.get('/getmachinedetails', (req, res) => {
  const sql = 'select * from machine'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//machinverall report

app.get('/machine_report', (req, res) => {
  const sql = 'SELECT * FROM machine'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//Machine update
app.put('/machine_update/:id', (req, res) => {
  const { id } = req.params;
  const { machineName, machineModel, machineS_No, machineSupName,machineSupMobile,purchaseRate,purchaseDate,warrantyDate,modifyDate } = req.body;

  const sql = 'UPDATE machine SET machineName = ?, machineModel = ?, machineS_No = ?,machineSupName = ?,machineSupMobile = ?,purchaseRate = ?,purchaseDate = ? ,warrantyDate = ?, modifyDate = ? WHERE id = ?';
  const values = [machineName, machineModel, machineS_No, machineSupName,machineSupMobile,purchaseRate,purchaseDate,warrantyDate,modifyDate,id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});

//machine delete
app.delete('/machinedelete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM machine WHERE id = ?';
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

//29/11
app.delete('/purchase_orderdelete/:orderNo', (req, res) => {
  const { orderNo } = req.params;
  console.log('Received DELETE request for orderNo:', orderNo);

  const sql = 'DELETE FROM purchase_order WHERE orderNo = ?';
  const values = [orderNo];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      console.log('Data deleted successfully');
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});
//delete pending sale order
app.delete('/delete_pending_sale/:orderNo', (req, res) => {
  const { orderNo } = req.params;
  console.log('Received DELETE request for orderNo:', orderNo);

  const sql = 'DELETE FROM pending_sales_order WHERE orderNo = ?';
  const values = [orderNo];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      console.log('Data deleted successfully');
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});

//02/12
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



app.get('/employee/:empID', (req, res) => {
  const empID = req.params.empID;

  const query = 'SELECT * FROM employee WHERE empID = ?';

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

//04/12
app.get('/checknonorderNo_Customer_order', (req, res) => {
  const sql = 'select * from purchase_order'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});




//20//12//23
app.get('/checkinvoiveNo_forbalancesheet', (req, res) => {
  const sql = 'select * from balance_sheet'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/checkinvoiveNo_forbalancesheet_purchase', (req, res) => {
  const sql = 'select * from balance_sheet_purchase'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getemployeein_shift', (req, res) => {
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


//23/12/23

/*app.get('/getemployeein_shift', (req, res) => {
  const sql = 'select * from shift'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});*/

/*app.get('/getemployeein_shiftdate', (req, res) => {
  const fromDate = req.query.fromDate; // Get the fromDate parameter from the request

  // Modify your SQL query to include the fromDate parameter
  const sql = `select * from shift where fromDate = '${fromDate}'`;

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});*/

app.get('/getemployeein_shiftdate', (req, res) => {
  const fromDate = req.query.fromDate; // Get the fromDate parameter from the request
  const toDate = req.query.toDate; // Get the fromDate parameter from the request
  const shiftType = req.query.shiftType; // Get the shiftType parameter from the request


  // Modify your SQL query to include the fromDate parameter and exclude the specified shiftType
  const sql = `SELECT * FROM shift WHERE fromDate <= '${fromDate}' AND toDate >='${toDate}' AND shiftType <> '${shiftType}'`;

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});



app.get('/fetch_empid_exists', (req, res) => {
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;


  const sql = `SELECT COUNT(*) AS count FROM shift WHERE fromDate = ? AND toDate = ?`;

  db.query(sql, [fromDate, toDate], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    const count = result[0].count;
    res.json({ exists: count > 0 });
  });
});

//29//12//2023
app.post('/updateReturnQty', async (req, res) => {
  const { prodCode, prodName, returnTotal, returnQty,  invoiceNo, modifyDate } = req.body;

  const sql = 'UPDATE purchase SET  returnTotal = ?, returnQty = ?, modifyDate = ? WHERE prodCode = ? AND prodName = ? AND invoiceNo = ?';
  const values = [returnTotal,returnQty, modifyDate, prodCode, prodName, invoiceNo];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});


app.get('/purchase_returnview', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM preturn WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});


//end raja



//elango

//shift


app.post('/shift_data', (req, res) => {
  const dataToInsert = req.body.dataToInsertSup;

  // Perform the MySQL insert query
  db.query('INSERT INTO shift SET ?', dataToInsert, (err, results) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/fetch_shift', (req, res) => {
  const sql = 'SELECT * FROM shift';
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
app.get('/shift_view', (req, res) => {
  const empID = req.query.empID;

  const sql = `SELECT * FROM shift WHERE empID = ?`;

  db.query(sql, [empID], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.put('/shift_update/:id', (req, res) => {
  const { id } = req.params;
  const { fromDate,toDate,shiftType,shiftTime,modifyDate } = req.body;

  const sql = 'UPDATE shift SET fromDate = ?, toDate = ?, shiftType = ?,shiftTime = ?,modifyDate = ? WHERE id = ?';
  const values = [fromDate,toDate,shiftType,shiftTime,modifyDate, id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.delete('/shift_delete/:id', (req, res) => {
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

//27//01
app.post('/rawmeterial_entry', (req, res) => {
  const { dataToInsertSupItem1 } = req.body;
  const sql = 'INSERT INTO raw_meterial_entry SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertSupItem1], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//27//01
app.get('/get_Raw_Material_report', (req, res) => {
  const sql = 'SELECT * FROM raw_meterial_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
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

//supplier items and entry (post)
app.post('/supplier_data', (req, res) => {
  const { dataToInsertSup } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO supplier SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertSup], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//new
app.post('/po_items', (req, res) => {
  const { dataToInsertSupItem1 } = req.body;
  const sql = 'INSERT INTO po SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertSupItem1], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/get_PO_entry_pdf', (req, res) => {
  const sql = 'select * from po'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
//supplier and item fetch
app.get('/fetch_po', (req, res) => {
  const { poNo } = req.query;
  const sql = `SELECT * FROM po WHERE poNo = '${poNo}'`;
  console.log('PO Query:', sql);

  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('PO Data fetched successfully');
      res.status(200).json(result);
    }
  });
});
app.get('/get_poNo', (req, res) => {
  const sql = 'SELECT * FROM po order by poNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/fetch_supplier', (req, res) => {
  const sql = 'SELECT * FROM supplier';
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
app.get('/fetch_supCode', (req, res) => {
  const sql = 'SELECT * FROM supplier';
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



app.get('/fetch_productname', (req, res) => {
  const sql = 'SELECT * FROM prodcode_entry';
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
app.get('/filter_supplier_name', (req, res) => {
  const sql = 'SELECT * FROM supplier';
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
app.get('/filter_po', (req, res) => {
  const sql = 'SELECT * FROM po';
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




//supplier view
app.get('/supplier_view', (req, res) => {
  const supCode = req.query.supCode;

  const sql = `SELECT * FROM supplier WHERE supCode = ?`;

  db.query(sql, [supCode], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
//supplier update
app.put('/supplier_update/:id', (req, res) => {
  const { id } = req.params;
  const { supName,supAddress,supMobile,modifyDate } = req.body;

  const sql = 'UPDATE supplier SET supName = ?, supAddress = ?, supMobile = ?,modifyDate = ? WHERE id = ?';
  const values = [supName, supAddress, supMobile,modifyDate, id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.get('/get_available_quantity', (req, res) => {
  const { prodCode, prodName } = req.query;

  const query = `SELECT qty FROM raw_material WHERE prodCode = ? AND prodName = ?`;

  db.query(query, [prodCode, prodName], (err, results) => {
    if (err) {
      console.error('Error executing query: ' + err.stack);
      res.status(500).json({ error: 'Internal Server Error' });
      return;
    }

    if (results.length === 0) {
      res.status(404).json({ error: 'Product not found' });
    } else {
      const qty = results[0].qty;
      res.json({ qty });
    }
  });
});
//supplier Delete
app.delete('/supplier_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM supplier WHERE id = ?';
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



//purchase entry


/*
app.get('/get_po_item', (req, res) => {
  const poNo = req.query.poNo;

  const sql = `SELECT * FROM po WHERE poNo = ?`;

  db.query(sql, [poNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
*/


//16//01
app.post('/purchase_entry_item', (req, res) => {
  const { dataToInsertSupItem } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO purchase SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertSupItem], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/purchase_entry_item_gsm', (req, res) => {
  const { dataToInsertSupItemGsm } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO purchase SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertSupItemGsm], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});


app.get('/fetch_po_data', (req, res) => {

  const poNo = req.query.poNo; // Get the poNo from the request query parameters  const getSupCodeSql = 'SELECT supCode FROM po WHERE poNo = ?';
  db.query(getSupCodeSql, [poNo], (err, result) => {
    if (err) {
      console.error('Error fetching supCode:', err);
      res.status(500).json({ error: 'Error fetching supCode' });
    } else {
      if (result && result[0] && result[0].supCode) {
        const supCode = result[0].supCode; // Assuming you have a single supCode for the given poNo
        const getSupplierDataSql = 'SELECT supCode, supName, supMobile, supAddress FROM supplier WHERE supCode = ?';
        db.query(getSupplierDataSql, [supCode], (err, result) => {
          if (err) {
            console.error('Error fetching supplier data:', err);
            res.status(500).json({ error: 'Error fetching supplier data' });
          } else {
            console.log('Data fetched successfully');
            res.status(200).json(result);
          }
        });
      } else {
        res.status(404).json({ error: 'No data found for the provided poNo' });
      }
    }
  });
});
app.post('/getSupplierInfo2', (req, res) => {
  const { poNo } = req.body;
  const query = `
    SELECT p.supCode, s.supName, s.supMobile, s.supAddress
    FROM po p
    JOIN supplier s ON p.supCode = s.supCode
    WHERE p.poNo = ?`;

  db.query(query, [poNo], (err, result) => {
    if (err) throw err;
    res.json(result[0]);
  });
});
app.get('/filter_purchase_report', (req, res) => {
  const sql = 'select * from purchase'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});







//po report
app.get('/get_po', (req, res) => {
 const sql = 'SELECT * FROM po';
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
app.get('/po_view_item', (req, res) => {
  const poNo = req.query.poNo;

  const sql = `SELECT * FROM po WHERE poNo = ?`;

  db.query(sql, [poNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/fetch_sup_details', (req, res) => {
  const supCode = req.query.supCode;

  const sql = `SELECT * FROM supplier WHERE supCode = ?`;

  db.query(sql, [supCode], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/get_purchase_return_invoice', (req, res) => {
 const sql = 'SELECT * FROM preturn';
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
app.get('/purchase_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM purchase WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

//purchase return
app.post('/purchase_ret', (req, res) => {
  const { dataToInsertPurchaseReturn } = req.body;
  const sql = 'INSERT INTO preturn SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertPurchaseReturn], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/get_returnNo', (req, res) => {
  const sql = 'SELECT * FROM preturn order by preturnNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/purchase_ret_item', (req, res) => {
  const { dataToInsertPurchaseReturnItem } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO preturn SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertPurchaseReturnItem], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/get_purchase_item', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = 'SELECT * FROM purchase WHERE invoiceNo = ?'; // Update the SQL query

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/get_purchase_items', (req, res) => {
  const poNo = req.query.poNo;
  const sql = 'SELECT * FROM purchase WHERE poNo = ?'; // Update the SQL query

  db.query(sql, [poNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
/*app.get('/get_purchase_item', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const supName = req.query.supName; // Add this line to get supplier name

  const sql = 'SELECT * FROM purchase WHERE invoiceNo = ? AND supName = ?'; // Update the SQL query

  db.query(sql, [invoiceNo, supName], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});*/
app.get('/get_preturn', (req, res) => {
 const sql = 'SELECT * FROM preturn';
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data kjh fetched successfully');
      res.status(200).json(result);
    }
  });
});
app.get('/get_preturn_view', (req, res) => {
  const preturnNo = req.query.preturnNo;

  const sql = `SELECT * FROM preturn WHERE preturnNo = ?`;

  db.query(sql, [preturnNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.post('/fetchItemGroupName', (req, res) => {
  const { itemGroup } = req.body;
  const query = `SELECT itemName FROM item WHERE itemGroup = ?`;

  db.query(query, [itemGroup], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ prodName: results[0].prodName });
    } else {
      res.json({ prodName: '' }); // Return an empty string if no match found
    }
  });
});


app.get('/fetch_supplier_data_pretuen', (req, res) => {
  const sql = 'SELECT * FROM supplier';
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

//sales return
app.get('/get_sales_return_name_for_suggestion', (req, res) => {
 const sql =`SELECT DISTINCT s.invoiceNo From sales_returns sr
                    LEFT JOIN sales s ON sr.invoiceNo <> s.invoiceNo`;
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
app.get('/get_sales_return_name_data', (req, res) => {
  const sql =`SELECT DISTINCT s.invoiceNo
              FROM sales s
              LEFT JOIN sales_returns sr ON s.invoiceNo = sr.invoiceNo
              WHERE sr.invoiceNo IS NULL
              ORDER BY s.invoiceNo DESC;
             `;

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
app.get('/sales_return_item_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM sales_returns WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.post('/sales_returns', (req, res) => {
  const { dataToInsertSalesReturn } = req.body;
  const sql = 'INSERT INTO sales_returns SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertSalesReturn], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data SalesReturn inserted successfully');
      res.status(200).json({ message: 'Data SalesReturn inserted successfully' });
    }
  });
});




app.put('/production/update/:itemGroup/:itemName/:size/:color', (req, res) => {
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const size = req.params.size;
  const color = req.params.color;
  const { saleInvNo,qtyIncrement } = req.body;

  console.log('Values before update:', req.body);
  const sql = 'UPDATE production_entry SET saleInvNo=?, qty=qty+? WHERE itemGroup=? AND itemName=? AND size=? AND color =?';
  const values = [saleInvNo, qtyIncrement, itemGroup, itemName, size, color];

//  const sql = 'UPDATE production_entry SET saleInvNo=? WHERE itemGroup=? AND itemName=?';
 // const values = [saleInvNo, itemGroup, itemName];
  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Production updated successfully');
    }
  });
});
app.put('/production_qty_increament/update/:machineName/:itemGroup/:itemName/:size/:color', (req, res) => {
  const machineName = req.params.machineName;
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const size = req.params.size;
  const color = req.params.color;
  const { qtyIncrement } = req.body;

  console.log('Values before update Production:', req.body);
  const sql = 'UPDATE production_entry SET  qty=qty+? WHERE machineName =? AND itemGroup=? AND itemName=? AND size=? AND color =?';
  const values = [qtyIncrement,machineName, itemGroup, itemName, size, color];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Production updated successfully');
    }
  });
});
app.get('/getmachname', (req, res) => {
  const sql = 'SELECT DISTINCT machineName FROM machine'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/getmachnamefinishing', (req, res) => {
  const sql = 'SELECT machineName FROM machine'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/update_production_entry_Field', (req, res) => {
  const { dataToInsertProduction } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO production_entry SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertProduction], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/get_sales_return_invoice', (req, res) => {
 const sql = 'SELECT * FROM sales_returns';
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

app.get('/get_sreturnNo', (req, res) => {
  const sql = 'SELECT * FROM sales_returns order by salRetNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/get_sales', (req, res) => {
 const sql = 'SELECT * FROM sales';
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
app.post('/sales_ret', (req, res) => {
  const { dataToInsertPurchaseReturn } = req.body;
  const sql = 'INSERT INTO sales_returns SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertPurchaseReturn], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/salRetNo_fetch', (req, res) => {
  const sql = 'SELECT * FROM sales_returns order by salRetNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/saleInvNo_fetch', (req, res) => {
  const sql = 'SELECT * FROM sales_returns order by saleInvNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
//production update
app.post('/sales_to_update_Production', async (req, res) => {
  const { itemGroup, itemName, size, color, invoiceNo, qty } = req.body;
  const sql = 'UPDATE production_entry SET invoiceNo=?, qty=qty-? WHERE itemGroup=? AND itemName=? AND size=? AND color=?';
  const values = [invoiceNo, qty, itemGroup, itemName, size, color];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});
app.post('/sales_return_update_Production', async (req, res) => {
  const { itemGroup, itemName, color, size, qty} = req.body;

  const sql = 'UPDATE production_entry SET  qty=qty+? WHERE itemGroup=? AND itemName=? AND color=? AND size=?';
  const values = [qty, itemName, itemName, color, size]; // <-- Corrected here

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error'); // Handle the error with a response
    } else {
      res.send('raw_material updated successfully'); // Send a success response
    }
  });
});

app.get('/itemGroups', (req, res) => {
  const sql = 'SELECT DISTINCT itemGroup FROM item ORDER BY itemGroup'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.get('/get_item_names_by_itemGroup', (req, res) => {
  const itemGroup = req.query.itemGroup;

  const sql = `SELECT itemName FROM item WHERE itemGroup = ? ORDER BY itemName`;

  db.query(sql, [itemGroup], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/get_size_by_iG_iN', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;

  const sql = `SELECT size FROM item WHERE itemGroup = ? AND itemName = ? ORDER BY size`;

  db.query(sql, [itemGroup,itemName], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/get_color_by_iG_iN', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;
  const size = req.query.size;

  const sql = `SELECT color FROM item WHERE itemGroup = ? AND itemName = ? AND size = ? ORDER BY color`;

  db.query(sql, [itemGroup,itemName,size], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});


app.post('/update_sales_item_salInvNo_Field', (req, res) => {
  const { invoiceNo, saleInvNo } = req.body;

  const sql ='UPDATE sales SET saleInvNo = ? WHERE invoiceNo = ?';

  db.query(sql, [saleInvNo, invoiceNo], (err, result) => {
    if (err) {
      console.error('Error updating field: ' + err.stack);
      res.status(500).send('Error updating field');
    } else {
      console.log('Field updated successfully');
      res.send('Field updated successfully');
    }
  });
});

app.post('/damage_entry', (req, res) => {
  const { dataToInsertdamage } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO damage SET ?'; // Modify to your table name

  db.query(sql, dataToInsertdamage, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/sales_return_item_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM sales_returns WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

//product Code

app.get('/get_product_code', (req, res) => {
  const sql = 'SELECT * FROM prodcode_entry order by prodCode desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/productcode_creation', (req, res) => {
  const { dataToInsertProduct } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO prodcode_entry SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertProduct], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/fetch_productCode', (req, res) => {
  const sql = 'SELECT * FROM prodcode_entry';
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('data fetched successfully');
      res.status(200).json(result);
    }
  });
});

app.get('/productcode_edit', (req, res) => {
  const prodCode= req.query.prodCode;


  const sql = `SELECT * FROM prodcode_entry WHERE prodName = ? AND  modifyDate = ? AND unit=?` ;

  db.query(sql, [prodCode], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.put('/product_update/:prodCode', (req, res) => {
  const prodCode = req.params.prodCode;
  const prodName = req.body.prodName;
      const unit = req.body.unit;
  const modifyDate = req.body.modifyDate;

  // Check if the prodName already exists in the database
  const checkQuery = `SELECT * FROM prodcode_entry WHERE prodName = ? AND unit=?`;
  db.query(checkQuery, [prodName,unit], (checkErr, checkResult) => {
    if (checkErr) {
      throw checkErr;
    }

    if (checkResult.length > 0) {
      // ProdName already exists, return a 409 (Conflict) status code
      res.status(409).json({ message: 'Product name already exists' });
    } else {
      // Update the record
      const updateQuery = `UPDATE prodcode_entry SET prodName = ?,unit=?, modifyDate = ? WHERE prodCode = ?`;
      db.query(updateQuery, [prodName,unit,modifyDate, prodCode], (updateErr, updateResult) => {
        if (updateErr) {
          throw updateErr;
        }
        res.status(200).json({ message: 'Product code updated successfully' });
      });
    }
  });
});


app.delete('/product_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM prodcode_entry WHERE id = ?';
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

app.post('/getSupplierInfo', (req, res) => {
  const { poNo } = req.body;
  const query = `
    SELECT p.supCode, s.supName, s.supMobile, s.supAddress
    FROM po p
    JOIN supplier s ON p.supCode = s.supCode
    WHERE p.poNo = ?`;

  db.query(query, [poNo], (err, result) => {
    if (err) throw err;
    res.json(result[0]);
  });
});
app.put('/returnTotal_update/:invoiceNo/:prodCode', (req, res) => {
  const { invoiceNo } = req.params;
  const { returnTotal,returnQty } = req.body;

  const sql = 'UPDATE purchase SET returnTotal = ?,returnQty = ? WHERE invoiceNo =  AND prodCode = ?';

  const values = [returnTotal,returnQty,invoiceNo,prodCode];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
//11/12
app.post('/addRawMaterial', async (req, res) => {
  const { prodCode, prodName, qty, unit, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET qty = qty + ?, modifyDate = ? WHERE prodCode = ? AND prodName = ? AND unit = ?';
  const values = [qty, modifyDate, prodCode, prodName, unit];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
app.post('/addRawMaterialGsm', async (req, res) => {
  const { prodCode, prodName, sNo, totalweight, unit, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET  totalweight = totalweight + ? , modifyDate = ? WHERE prodCode = ? AND prodName = ? AND unit = ? AND sNo = ? ';
  const values = [totalweight, modifyDate, prodCode, prodName, unit, sNo];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});

app.post('/Raw_material_entry_gsm', (req, res) => {
  const { dataToInsertRawGsm } = req.body;
  const sql = 'INSERT INTO raw_material SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertRawGsm], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.post('/Raw_material_entry', (req, res) => {
  const { dataToInsertRaw } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO raw_material SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertRaw], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/get_purchase', (req, res) => {
 const sql = 'SELECT * FROM purchase ORDER BY invoiceNo DESC';
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

app.get('/get_po_item', (req, res) => {
  const poNo = req.query.poNo;

  const sql = `SELECT p.prodCode, p.prodName,p.qty,p.deliveryDate,p.supCode,p.poNo,p.date, i.unit FROM po p
               LEFT JOIN prodcode_entry i ON p.prodCode=i.prodCode AND p.prodName=i.prodName
                WHERE poNo = ?`;

  db.query(sql, [poNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/fetch_po_datas', (req, res) => {
  const sql = 'SELECT * FROM po ORDER BY poNo DESC';
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

app.get('/fetch_supplier_data', (req, res) => {
  const sql = 'SELECT * FROM supplier';
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
app.get('/fetch_productcode_duplicate', (req, res) => {
  const sql = 'SELECT * FROM raw_material';
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
app.get('/fetch_productcode_duplicate_gsm', (req, res) => {
  const sql = 'SELECT * FROM raw_material';
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

//16//01
/*app.post('/purchase_entry_item', (req, res) => {
  const { dataToInsertSupItem2 } = req.body;
  const sql = 'INSERT INTO purchase SET ?';
  db.query(sql, [dataToInsertSupItem2], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});*/
app.post('/fetchProductName', (req, res) => {
  const { prodCode } = req.body;
  const query = `SELECT prodName FROM prodcode_entry WHERE prodCode = ?`;

  db.query(query, [prodCode], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ prodName: results[0].prodName });
    } else {
      res.json({ prodName: '' }); // Return an empty string if no match found
    }
  });
});
app.post('/fetchProductCode', (req, res) => {
  const { prodName } = req.body;
  const query = `SELECT prodCode FROM prodcode_entry WHERE prodName = ?`;

  db.query(query, [prodName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ prodCode: results[0].prodCode });
    } else {
      res.json({ prodCode: '' }); // Return an empty string if no match found
    }
  });
});

app.post('/fetchUnitInPO', (req, res) => {
  const { prodCode, prodName } = req.body;
  const query = `SELECT unit FROM prodcode_entry WHERE prodCode = ? AND prodName = ?`;

  db.query(query, [prodCode, prodName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ unit: results[0].unit });
    } else {
      res.json({ unit: '' }); // Return an empty string if no match found
    }
  });
});

app.post('/updatePurchaseRqty', async (req, res) => {
  const { prodCode, prodName, qty, invoiceNo, modifyDate } = req.body;

  const sql = 'UPDATE purchase SET  qty = ?, modifyDate = ? WHERE prodCode = ? AND prodName = ? AND invoiceNo = ?';
  const values = [qty, modifyDate, prodCode, prodName, invoiceNo];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});

app.post('/updateRawMaterial', async (req, res) => {
  const { prodCode, prodName, qty,totalweight, unit, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET qty = qty - ?, totalweight =totalweight - ?, modifyDate = ? WHERE prodCode = ? AND prodName = ? AND unit = ?';
  const values = [qty,totalweight, modifyDate, prodCode, prodName, unit];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
//21/12/23

app.post('/fetchSuggestions', (req, res) => {
  const { pattern } = req.body;
  const query = `
    SELECT prodCode, prodName
    FROM prodcode_entry
    WHERE prodCode LIKE ? OR prodName LIKE ?
  `;
  const patternWithWildcards = `%${pattern}%`;

  db.query(query, [patternWithWildcards, patternWithWildcards], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    const suggestions = results.map((result) => {
      // Combine prodCode and prodName to display in suggestions
      return `${result.prodCode} - ${result.prodName}`;
    });

    res.json({ suggestions });
  });
});



//attendance
app.get('/get_punch', (req, res) => {
  const sql = 'SELECT * FROM iclock_transaction'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.post('/updateAttendance', (req, res) => {
  const { emp_code, inDate, first_name, shiftType, check_in, lunch_out, lunch_in, check_out, latecheck_in, late_lunch, earlycheck_out, req_time, act_time, remark } = req.body;

  const updateQuery = `UPDATE attendance SET
    first_name = ?,
    shiftType = ?,
    check_in = ?,
    lunch_out = ?,
    lunch_in = ?,
    check_out = ?,
    latecheck_in = ?,
    late_lunch = ?,
    earlycheck_out = ?,
    req_time = ?,
    act_time = ?,
    remark = ?
    WHERE emp_code = ? AND inDate = ?`;

  db.query(
    updateQuery,
    [ first_name, shiftType, check_in, lunch_out, lunch_in, check_out, latecheck_in, late_lunch, earlycheck_out, req_time, act_time, remark, emp_code, inDate ],
    (error, results) => {
      if (error) {
        console.error('Error updating attendance:', error);
        res.status(500).send('Error updating attendance');
      } else {
        console.log('Attendance updated successfully');
        res.status(200).send('Attendance updated successfully');
      }
    }
  );
});
app.get('/get_attendance_alter', (req, res) => {
 const sql = 'SELECT * FROM attendance';
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

app.get('/attendance_view_morning', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format
  const sql = `
    SELECT
      CASE
        WHEN s.alterEmpID IS NOT NULL THEN e_alter.emp_code
        ELSE e.emp_code
      END AS emp_code,
      CASE
        WHEN s.alterEmp IS NOT NULL THEN e_alter.first_name
        ELSE e.first_name
      END AS first_name,
      CASE
        WHEN s.alterEmpID IS NOT NULL THEN e_alter.salary
        ELSE e.salary
      END AS salary,
      CASE
        WHEN s.alterEmpID IS NOT NULL THEN e_alter.salaryType
        ELSE e.salaryType
      END AS salaryType,
      it.punch_time,
      s.shiftType,
      s.fromDate,
      s.toDate,
      s.shiftTime
    FROM
      shift s
    JOIN
      iclock_transaction it ON (s.emp_code = it.emp_code OR s.alterEmpID = it.emp_code)
    LEFT JOIN
      employee e ON s.emp_code = e.emp_code
    LEFT JOIN
      employee e_alter ON s.alterEmpID = e_alter.emp_code
    WHERE
      s.fromDate <= ? AND
      s.toDate >= ? AND
      s.shiftType = 'Morning' AND
      ? BETWEEN s.fromDate AND s.toDate AND
      (DATE(it.punch_time) = ? OR DATE(it.punch_time) IS NULL)
  `;

  db.query(sql, [currentDate, currentDate, currentDate, currentDate], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.json(result);
    }
  });
});



/*
app.get('/attendance_view_general', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format
  const sql = `
    SELECT
      e.emp_code,
      e.first_name,
      e.salary,
      e.salaryType,
      it.punch_time,
      'shift1' AS shiftType

    FROM
      employee e
    LEFT JOIN
      iclock_transaction it ON e.emp_code = it.emp_code
    WHERE
      e.shift = 'shift1' AND
      (DATE(it.punch_time) = ? OR DATE(it.punch_time) IS NULL)
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
*/


/*app.get('/attendance_view_general', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format
  const sql = `
    SELECT
      CASE
        WHEN s.alterEmpID IS NOT NULL THEN e_alter.emp_code
        ELSE e.emp_code
      END AS emp_code,
      CASE
        WHEN s.alterEmp IS NOT NULL THEN e_alter.first_name
        ELSE e.first_name
      END AS first_name,
      CASE
        WHEN s.alterEmpID IS NOT NULL THEN e_alter.salary
        ELSE e.salary
      END AS salary,
      CASE
        WHEN s.alterEmpID IS NOT NULL THEN e_alter.salaryType
        ELSE e.salaryType
      END AS salaryType,
      it.punch_time,
      s.shiftType,
      s.fromDate,
      s.toDate,
      s.shiftTime
    FROM
      shift s
    JOIN
      iclock_transaction it ON (s.emp_code = it.emp_code OR s.alterEmpID = it.emp_code)
    LEFT JOIN
      employee e ON s.emp_code = e.emp_code
    LEFT JOIN
      employee e_alter ON s.alterEmpID = e_alter.emp_code
    WHERE
      (s.fromDate <= ? AND s.toDate >= ? AND s.shiftType = 'General') AND
      ((? BETWEEN s.fromDate AND s.toDate) OR (s.alterEmpID IS NOT NULL AND ? BETWEEN s.fromDate AND s.toDate)) AND
      (DATE(it.punch_time) = ? OR DATE(it.punch_time) IS NULL)
  `;

  db.query(sql, [currentDate, currentDate, currentDate, currentDate, currentDate], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.json(result);
    }
  });
});*/
/*
app.get('/attendance_view_night', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayDate = yesterday.toISOString().split('T')[0]; // Get yesterday's date in 'YYYY-MM-DD' format

  const sql = `
    SELECT
      e.emp_code,
      e.first_name,
      e.salary,
      e.salaryType,
      it.punch_time,
      s.shiftType,
      s.fromDate,
      s.toDate,
      s.shiftTime
    FROM
      employee e
    JOIN
      iclock_transaction it ON e.emp_code = it.emp_code
    LEFT JOIN
      shift s ON e.emp_code = s.emp_code
    WHERE
      s.fromDate <= ? AND
      s.toDate >= ? AND
      s.shiftType = 'Night' AND
      ((? BETWEEN s.fromDate AND s.toDate) OR (? BETWEEN s.fromDate AND s.toDate)) AND
      (
        (DATE(it.punch_time) = ? AND TIME(it.punch_time) BETWEEN '18:00:00' AND '21:00:00') OR
        (DATE(it.punch_time) = ? AND TIME(it.punch_time) BETWEEN '18:00:00' AND '21:00:00')
      )
    ORDER BY e.emp_code, it.punch_time;
  `;

  db.query(sql, [currentDate, currentDate, yesterdayDate, yesterdayDate, yesterdayDate, currentDate], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.json(result);
    }
  });
});
*/
app.get('/attendance_view_night', (req, res) => {
  // Get current date and calculate date for two days before
  const currentDate = new Date();
  const twoDaysBefore = new Date(currentDate.getTime() - (2 * 24 * 60 * 60 * 1000));
  const currentDateStr = currentDate.toISOString().split('T')[0]; // Convert to 'YYYY-MM-DD' format
  const twoDaysBeforeStr = twoDaysBefore.toISOString().split('T')[0]; // Convert to 'YYYY-MM-DD' format

  const sql = `
    SELECT
      e.emp_code,
      e.first_name,
      e.salary,
      e.salaryType,
      it.punch_time,
      s.shiftType,
      s.fromDate,
      s.toDate,
      s.shiftTime
    FROM
      employee e
    JOIN
      iclock_transaction it ON e.emp_code = it.emp_code
    LEFT JOIN
      shift s ON e.emp_code = s.emp_code
    WHERE
      s.fromDate <= ? AND
      s.toDate >= ? AND
      s.shiftType = 'Night' AND
      ? BETWEEN s.fromDate AND s.toDate AND
      DATE(it.punch_time) >= ? AND DATE(it.punch_time) <= ?
    ORDER BY e.emp_code, it.punch_time;
  `;

  // Note the addition of twoDaysBeforeStr and currentDateStr at the end of the parameter list for the query
  db.query(sql, [currentDateStr, currentDateStr, currentDateStr, twoDaysBeforeStr, currentDateStr], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.json(result);
    }
  });
});

/*
app.get('/attendance_view_night', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format

  const sql = `
    SELECT
      e.emp_code,
      e.first_name,
      e.salary,
      e.salaryType,
      it.punch_time,
      s.shiftType,
      s.fromDate,
      s.toDate,
      s.shiftTime
    FROM
      employee e
    JOIN
      iclock_transaction it ON e.emp_code = it.emp_code
    LEFT JOIN
      shift s ON e.emp_code = s.emp_code
    WHERE
      s.fromDate <= ? AND
      s.toDate >= ? AND
      s.shiftType = 'Night' AND
      ? BETWEEN s.fromDate AND s.toDate
    ORDER BY e.emp_code, it.punch_time;
  `;

  db.query(sql, [currentDate, currentDate, currentDate], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.json(result);
    }
  });
});
*/

app.get('/get_attendance_report', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in 'YYYY-MM-DD' format

  const sql = `
    SELECT iclock_transaction.*, employee.first_name, shift.shiftType, shift.fromDate, shift.toDate, shift.shiftTime, employee.salary, employee.salaryType
    FROM iclock_transaction
    JOIN employee ON iclock_transaction.emp_code = employee.emp_code
    LEFT JOIN shift ON iclock_transaction.emp_code = shift.emp_code
    WHERE shift.fromDate <= '${currentDate}' AND shift.toDate >= '${currentDate}'
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});




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
//end elango


//start bhuvana
//stock


app.get('/winding_entry_get_report', (req, res) => {

//  const sql = 'SELECT createdate,opOneName,machName,assOne,asstwo,shiftType,status FROM winding_entry';
  const sql = 'SELECT * from daily_work_status';

  //const sql = 'SELECT*FROM winding_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
//winding_entry
/*
app.get('/winding_entry_get_report', (req, res) => {
  const sql = 'SELECT id,machName,assOne,assTwo,opOneName,shiftType,date FROM winding_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});///windinig code
*/
app.get('/get_winding_code', (req, res) => {
  const sql = 'SELECT * FROM winding_entry order by winding_ID desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


//finishing_entry
app.post('/finishing_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO finishing_entry SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});


/*
app.get('/finishing_entry_get_report', (req, res) => {
  const sql = 'SELECT id, machName, assOne,assTwo,assthree,opOneName,optwoName,shiftType,date FROM finishing_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
*/
//sales
app.post('/sales_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO sales SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/sales_invNo_fetch', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/sales_item_invNo_fetch', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
// size entry
app.post('/size_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO size_entry SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/size_entry', (req, res) => {
  const sql = 'SELECT id, size FROM size_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.put('/size_update/:id', (req, res) => {
  const { id } = req.params;
  const { size } = req.body;

  const sql = 'UPDATE size_entry SET size = ? WHERE id = ?'; // SQL query to update the itemGroup
  const values = [size, id]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.delete('/size_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM size_entry WHERE id = ?';
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
// color
app.put('/color_update/:id', (req, res) => {
  const { id } = req.params;
  const { color } = req.body;

  const sql = 'UPDATE color_entry SET color = ? WHERE id = ?'; // SQL query to update the itemGroup
  const values = [color, id]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.delete('/color_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM color_entry WHERE id = ?';
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
app.post('/color_entry', (req, res) => {
  const { dataToInsert } = req.body;
  const sql = 'INSERT INTO color_entry SET ?';
  db.query(sql, [dataToInsert], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/color_entry', (req, res) => {
  const sql = 'SELECT id, color FROM color_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/item_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO item SET ?'; // Modify to your table name
  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//UNIT
app.post('/unit_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO unit_entry SET ?'; // Modify to your table name
  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/unit_entry', (req, res) => {
  const sql = 'SELECT id, unit,packsize FROM unit_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.put('/unit_update/:id', (req, res) => {
  const { id } = req.params;
  const { unit } = req.body;

  const sql = 'UPDATE unit_entry SET unit = ? WHERE id = ?'; // SQL query to update the itemGroup
  const values = [unit, id]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});


app.delete('/unit_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM unit_entry WHERE id = ?';
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

// GST entry
app.post('/gst_entry', (req, res) => {
  const { dataToInsert } = req.body;
  const sql = 'INSERT INTO gst_entry SET ?';
  db.query(sql, [dataToInsert], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.put('/gst_update/:id', (req, res) => {
  const { id } = req.params;
  const { gst } = req.body;

  const sql = 'UPDATE gst_entry SET gst = ? WHERE id = ?'; // SQL query to update the itemGroup
  const values = [gst, id]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.delete('/gst_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM gst_entry WHERE id = ?';
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

app.get('/gst_entry', (req, res) => {
  const sql = 'SELECT id, gst FROM gst_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//itemgroup
//check item_groups
app.post('/post_itemgroup', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO item_groups SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/getall_item_groups', (req, res) => {
  const sql = 'SELECT * FROM item_groups'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.post('/itemcreation', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO item SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/fetch_item_duplicate', (req, res) => {
  const sql = 'SELECT * FROM item';
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

app.get('/getallitem', (req, res) => {
  const sql = 'SELECT * FROM item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.delete('/item_delete/:itemName', (req, res) => {
  const { itemName } = req.params;

  const sql = 'DELETE FROM item WHERE itemName = ?';
  const values = [itemName];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});

app.get('/getitemname', (req, res) => {
  const sql = 'SELECT DISTINCT itemName FROM item ORDER BY itemName ASC'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});




app.get('/getpurchase_order', (req, res) => {
  const sql = 'SELECT * FROM purchase_order_sale'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});










app.get('/fetching_customer_details', (req, res) => {
  const sql = 'SELECT * FROM customer';
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

app.get('/fetch_customer_details', (req, res) => {
  const sql = 'SELECT * FROM customer';
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
app.get('/get_sales_name_for_suggestion', (req, res) => {
 const sql =`SELECT DISTINCT p.orderNo From sales s
                    LEFT JOIN pending_sales_order p ON s.orderNo <> p.orderNo`;
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
app.get('/get_sales_return_name_for_suggestion', (req, res) => {
 const sql =`SELECT DISTINCT s.invoiceNo From sales_returns sr
                    LEFT JOIN sales s ON sr.invoiceNo <> s.invoiceNo`;
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
app.get('/get_sales_return_name_data', (req, res) => {
  const sql =`SELECT DISTINCT s.invoiceNo
              FROM sales s
              LEFT JOIN sales_returns sr ON s.invoiceNo = sr.invoiceNo
              WHERE sr.invoiceNo IS NULL
              ORDER BY s.invoiceNo DESC;
             `;

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

/*
app.get('/get_sales_name', (req, res) => {
 const sql =` SELECT DISTINCT p.orderNo, p.custCode, p.custName From sales s
                    LEFT JOIN purchase_order p ON s.orderNo <> p.orderNo`;
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
*/
app.get('/get_item_Group_in_sales_page', (req, res) => {
  const sql = 'SELECT DISTINCT itemGroup FROM item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      const itemGroups = results.map((result) => result.itemGroup);
      res.status(200).json(itemGroups);
    }
  });
});
app.get('/get_item_Name_in_sales_page', (req, res) => {
  const sql = 'SELECT DISTINCT itemName FROM item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      const itemNames = results.map((result) => result.itemName);
      res.status(200).json(itemNames);
    }
  });
});



app.get('/get_invoice_no', (req, res) => {
  const sql = 'SELECT * FROM sales order by invoiceNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/get_sales_entry_overall', (req, res) => {
  const sql = 'SELECT * FROM sales';
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


app.get('/get_sales_invoice', (req, res) => {
 const sql = 'SELECT * FROM sales';
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




//production_entry


app.post('/production_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO production_entry SET ?'; // Modify to your table name

  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/production_overall', (req, res) => {
  const { dataToInsert2 } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO stock SET ?'; // Modify to your table name

  db.query(sql, [dataToInsert2], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.post('/stock_insert', (req, res) => {
  const { dataToInsert2 } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO stock SET ?'; // Modify to your table name

  db.query(sql, [dataToInsert2], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/production_entry_get_report', (req, res) => {
  const sql = 'SELECT * FROM production_entry';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/production_overall_get_report', (req, res) => {
//  const sql = 'SELECT id, machineName, itemGroup, itemName, size, color, qty, date FROM production_entry'; // Select only id and unit fields
 const sql ='SELECT * FROM production_entry';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//raw material stock
app.get('/get_Raw_Material', (req, res) => {
  const sql = 'SELECT * FROM raw_material'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//11/12
app.get('/damage_get_report', (req, res) => {
  const sql = 'SELECT * FROM damage';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/get_sales_return_report', (req, res) => {
  const sql = `select  s.invoiceNo,  s.salRetNo,  s.custCode,  s.date,  s.grandTotal, s. saleInvNo,  s.itemGroup, s. itemName,  s.qty,  s.rate,  s.amt,  s.amtGST,  s.total, c.custName, c.custAddress,c.custMobile
   from sales_returns s
   left join customer c on s.custCode = c.custCode`; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/get_sales_returns_individual_report', (req, res) => {
  const salRetNo = req.query.salRetNo;

  const sql = `select s.invoiceNo,  s.salRetNo,  s.custCode,  s.date,  s.grandTotal, s. saleInvNo,  s.itemGroup, s. itemName,  s.qty,  s.rate,  s.amt,  s.amtGST,  s.total, c.custName, c.custAddress,c.custMobile
                  from sales_returns s
                  left join customer c on s.custCode = c.custCode
                  where salRetNo = ?`;

  db.query(sql, [salRetNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/sales_customer_details_get_view', (req, res) => {
  const custCode = req.query.custCode;

  const sql = `SELECT * FROM sales WHERE custCode = ?`;

  db.query(sql, [custCode], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});




app.get('/sales_item_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  //const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/sales_item_viewkv', (req, res) => {
  const kvinvoice = req.query.kvinvoice;

  //const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  const sql = `SELECT * FROM sales WHERE kvinvoice = ?`;

  db.query(sql, [kvinvoice], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/get_pending_name_for_suggestion', (req, res) => {
 //const sql =`SELECT DISTINCT * From pending_report ORDER BY pendingOrderNo DESC`;
 const sql =`SELECT *
                        FROM pending_report po
                        WHERE NOT EXISTS (
                            SELECT 1
                            FROM sales s
                            WHERE FIND_IN_SET(po.pendingOrderNo, REPLACE(s.orderNo, ' ', '')) > 0
                          );`;
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
app.get('/pendingInvNo_fetch', (req, res) => {
  const sql = 'SELECT * FROM pending_report order by pendingOrderNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
 //sales
app.post('/pending_insert', (req, res) => {
  const { datapendingInsert } = req.body;
    const sql = 'INSERT INTO pending_report SET ?';
  db.query(sql, [datapendingInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

 app.post('/sales_insert', (req, res) => {
   const { dataToInsertPurchaseReturnItem } = req.body;
     const sql = 'INSERT INTO sales SET ?';
   db.query(sql, [dataToInsertPurchaseReturnItem], (err, result) => { // Wrap dataToInsert in an array
     if (err) {
       console.error('Error inserting data:', err);
       res.status(500).json({ error: 'Error inserting data' });
     } else {
       console.log('Data inserted successfully');
       res.status(200).json({ message: 'Data inserted successfully' });
     }
   });
 });

app.get('/get_sales_product_items', (req, res) => {
  try {
    const orderNumbersParam = req.query.orderNumbers;
    const custCode = req.query.custCode; // Fetch custCode from query parameters

    if (!orderNumbersParam || !custCode) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order numbers or custCode not provided.' });
    }

    const orderNumbers = orderNumbersParam.split(',');
    const placeholders = orderNumbers.map(() => '?').join(', ');

    const query = `
      SELECT
        p.custName,
        p.custCode,
        p.orderNo,
        p.deliveryType,
        p.itemGroup,
        p.itemName,
        CONCAT(DATE_FORMAT(p.date, '%d-%m-'), SUBSTRING(YEAR(p.date), 3)) as date,
        p.qty,
        i.packSize,
        i.gst,
        i.hsnCode,
        c.rate  -- Added customer rate here
      FROM
        pending_sales_order p
      LEFT JOIN
        item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
      LEFT JOIN
        customer c ON p.custCode = c.custCode  -- Added customer join here
      WHERE
        p.orderNo IN (${placeholders}) AND
        p.custCode = ?
    `;

    db.query(query, [...orderNumbers, custCode], (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});


/*
app.get('/get_sales_product_items', (req, res) => {
  try {
    const orderNumbersParam = req.query.orderNumbers;
    const custCode = req.query.custCode; // Fetch custCode from query parameters

    if (!orderNumbersParam || !custCode) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order numbers or custCode not provided.' });
    }

    const orderNumbers = orderNumbersParam.split(',');
    const placeholders = orderNumbers.map(() => '?').join(', ');

    const query = `
      SELECT
        p.custName,
        p.custCode,
        p.orderNo,
        p.deliveryType,
        p.itemGroup,
        p.itemName,
        CONCAT(DATE_FORMAT(p.date, '%d-%m-'), SUBSTRING(YEAR(p.date), 3)) as date,
        p.qty,
        i.unit,
        i.gst,
        i.hsnCode,
        c.rate  -- Added customer rate here
      FROM
        purchase_order p
      LEFT JOIN
        item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
      LEFT JOIN
        stock s ON s.itemGroup = p.itemGroup AND s.itemName = i.itemName
      LEFT JOIN
        customer c ON p.custCode = c.custCode  -- Added customer join here
      WHERE
        p.qty <= s.qty AND
        p.orderNo IN (${placeholders}) AND
        p.custCode = ?
    `;

    db.query(query, [...orderNumbers, custCode, ...orderNumbers], (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});*/

 app.get('/get_sales_items', (req, res) => {
   const orderNo = req.query.orderNo;

   const sql = `SELECT p.custName,p.custCode,p.orderNo,p.deliveryType,p.itemGroup,p.itemName,p.qty,i.rate,i.unit,i.gst FROM purchase_order p
                  LEFT JOIN item i ON p.itemGroup=i.itemGroup AND p.itemName=i.itemName
                  LEFT join stock s ON s.itemGroup=p.itemGroup AND s.itemName=p.itemName
                  WHERE p.qty <=s.qty and orderNo = ?`

   db.query(sql, [orderNo], (err, result) => {
     if (err) {
       throw err;
     }
     res.json(result);
   });
 });
 app.get('/get_sales_edit', (req, res) => {
    const invoiceNo = req.query.invoiceNo;

    const sql = `SELECT * from sales where invoiceNo =?`;

    db.query(sql, [invoiceNo], (err, result) => {
      if (err) {
        throw err;
      }
      res.json(result);
    });
  });
 app.get('/fetch_pending_customer_details', (req, res) => {
   const sql = 'SELECT * FROM customer';
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
/*
app.get('/get_pending_items', (req, res) => {
   try {
     const pendingOrderNosParam = req.query.pendingOrderNos;

     if (!pendingOrderNosParam) {
       return res.status(400).json({ error: 'Bad Request', message: 'pendingOrderNo numbers not provided.' });
     }

     const pendingOrderNos = pendingOrderNosParam.split(',');

     const placeholders = pendingOrderNos.map(() => '?').join(', ');


     const query = `
           SELECT
            p.custName, p.custCode,p.individualOrderNo as orderNo, p.itemGroup, p.itemName, p.itemName,CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) as date, p.qty, i.rate, i.unit, i.gst
          FROM
            pending_report p
          LEFT JOIN
            item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
          LEFT JOIN
            stock s ON s.itemGroup = p.itemGroup AND s.itemName = p.itemName
          WHERE
            CAST(p.qty AS SIGNED) <=s.qty AND CAST(p.qty AS SIGNED)<>0 AND p.pendingOrderNo IN (${placeholders})

              UNION

                    SELECT
                      p.custName, p.custCode,p.individualOrderNo as orderNo,p.itemGroup, p.itemName, p.itemName,CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) as date, s.qty, i.rate, i.unit, i.gst
                    FROM
                      pending_report p
                    LEFT JOIN
                      item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
                    LEFT JOIN
                      stock s ON s.itemGroup = p.itemGroup AND s.itemName = p.itemName
                    WHERE
                        p.pendingOrderNo IN (${placeholders}) and s.qty<>'0'  AND (s.qty IS NULL OR s.qty <  CAST(p.qty AS SIGNED))

     `;
    db.query(query, [...pendingOrderNos, ...pendingOrderNos], (error, results) => {
       if (error) {
         console.error('4312 Error executing query:', error);
         res.status(500).json({ error: '4312 Internal Server Error', message: error.message });
       } else {
         res.json(results);
       }
     });
   } catch (error) {
     console.error('Error:', error);
     res.status(500).json({ error: 'Internal Server Error', message: error.message });
   }
 });
*/
/*
app.get('/get_pending_items', (req, res) => {
   try {
     const pendingOrderNosParam = req.query.pendingOrderNos;

     if (!pendingOrderNosParam) {
       return res.status(400).json({ error: 'Bad Request', message: 'pendingOrderNo numbers not provided.' });
     }

     const pendingOrderNos = pendingOrderNosParam.split(',');

     const placeholders = pendingOrderNos.map(() => '?').join(', ');


     const query = `
           SELECT
            p.custName, p.custCode,p.individualOrderNo as orderNo, p.itemGroup, p.itemName, p.itemName,CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) as date, p.qty, i.rate, i.unit, i.gst
          FROM
            pending_report p
          LEFT JOIN
            item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
          LEFT JOIN
            stock s ON s.itemGroup = p.itemGroup AND s.itemName = p.itemName
          WHERE
           CAST(p.qty AS SIGNED)<>0 AND p.pendingOrderNo IN (${placeholders})


     `;
    db.query(query, [...pendingOrderNos, ...pendingOrderNos], (error, results) => {
       if (error) {
         console.error('4312 Error executing query:', error);
         res.status(500).json({ error: '4312 Internal Server Error', message: error.message });
       } else {
         res.json(results);
       }
     });
   } catch (error) {
     console.error('Error:', error);
     res.status(500).json({ error: 'Internal Server Error', message: error.message });
   }
 });
*/

/*app.get('/get_pending_items', (req, res) => {
   try {
     const pendingOrderNosParam = req.query.pendingOrderNos;

     if (!pendingOrderNosParam) {
       return res.status(400).json({ error: 'Bad Request', message: 'pendingOrderNo numbers not provided.' });
     }

     const pendingOrderNos = pendingOrderNosParam.split(',');

     const placeholders = pendingOrderNos.map(() => '?').join(', ');


     const query = `
           SELECT
            p.custName, p.custCode,p.individualOrderNo as orderNo, p.itemGroup, p.itemName, p.itemName,CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) as date, p.qty, i.rate, i.unit, i.gst
          FROM
            pending_report p
          LEFT JOIN
            item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
          LEFT JOIN
            stock s ON s.itemGroup = p.itemGroup AND s.itemName = p.itemName
          WHERE
            CAST(p.qty AS SIGNED) <=s.qty AND CAST(p.qty AS SIGNED)<>0 AND p.pendingOrderNo IN (${placeholders})

              UNION

                    SELECT
                      p.custName, p.custCode,p.individualOrderNo as orderNo,p.itemGroup, p.itemName, p.itemName,CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) as date, s.qty, i.rate, i.unit, i.gst
                    FROM
                      pending_report p
                    LEFT JOIN
                      item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
                    LEFT JOIN
                      stock s ON s.itemGroup = p.itemGroup AND s.itemName = p.itemName
                    WHERE
                        p.pendingOrderNo IN (${placeholders}) and s.qty<>'0'  AND (s.qty IS NULL OR s.qty <  CAST(p.qty AS SIGNED))

     `;
    db.query(query, [...pendingOrderNos, ...pendingOrderNos], (error, results) => {
       if (error) {
         console.error('4312 Error executing query:', error);
         res.status(500).json({ error: '4312 Internal Server Error', message: error.message });
       } else {
         res.json(results);
       }
     });
   } catch (error) {
     console.error('Error:', error);
     res.status(500).json({ error: 'Internal Server Error', message: error.message });
   }
 });*/



 app.get('/stock_get_report', (req, res) => {
   const sql = 'SELECT * FROM stock';
   db.query(sql, (err, results) => {
     if (err) {
       console.error('Error fetching data:', err);
       res.status(500).json({ error: 'Error fetching data' });
     } else {
       res.status(200).json(results);
     }
   });
 });

 app.get('/get_sales_name', (req, res) => {
   const sql =`SELECT DISTINCT * From purchase_order`;

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

app.get('/get_pending_name', (req, res) => {
  const sql =`SELECT DISTINCT * From pending_report`;

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

app.get('/get_sales_name_for_suggestion', (req, res) => {
  const custCode = req.query.custCode; // Assuming custCode is passed as a query parameter

  let sql;

  if (custCode) {
    sql = `SELECT DISTINCT po.orderNo
           FROM pending_sales_order po
           WHERE po.custCode = ?
             AND NOT EXISTS (
               SELECT 1
               FROM sales s
               WHERE FIND_IN_SET(po.orderNo, REPLACE(s.orderNo, ' ', '')) > 0
             );`;
  } else {
    sql = `SELECT DISTINCT po.orderNo
           FROM pending_sales_order po
           WHERE NOT EXISTS (
               SELECT 1
               FROM sales s
               WHERE FIND_IN_SET(po.orderNo, REPLACE(s.orderNo, ' ', '')) > 0
             );`;
  }

  db.query(sql, [custCode], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});

app.get('/get_sales_entry', (req, res) => {
 const sql = 'SELECT * FROM sales';
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

app.post('/sales_returns', (req, res) => {
  const { dataToInsertSalesReturn } = req.body;
  const sql = 'INSERT INTO sales_returns SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertSalesReturn], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data SalesReturn inserted successfully');
      res.status(200).json({ message: 'Data SalesReturn inserted successfully' });
    }
  });
});

app.get('/get_sales_item', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.post('/damage_entry', (req, res) => {
  const { dataToInsertdamage } = req.body;

  const sql = 'INSERT INTO damage SET ?'; // Modify to your table name

  db.query(sql, dataToInsertdamage, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.put('/damage/update/:itemGroup/:itemName', (req, res) => {
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const { qtyIncrement } = req.body;

  console.log('Values before update:', req.body);
  const sql = 'UPDATE damage SET  qty=qty+? WHERE itemGroup=? AND itemName=? ';
  const values = [qtyIncrement, itemGroup, itemName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Production updated successfully');
    }
  });
});


app.post('/update_sales_salInvNo_Field', (req, res) => {
  const { invoiceNo, saleInvNo } = req.body;

  const sql ='UPDATE sales SET saleInvNo = ? WHERE invoiceNo = ?';

  db.query(sql, [saleInvNo, invoiceNo], (err, result) => {
    if (err) {
      console.error('Error updating field: ' + err.stack);
      res.status(500).send('Error updating field');
    } else {
      console.log('Field updated successfully');
      res.send('Field updated successfully');
    }
  });
});

app.get('/get_pending_report', (req, res) => {
 const sql = `SELECT id, custCode, custName, deliveryType, itemGroup, itemName, qty, pincode, date, orderNo, custAddress, custMobile, pendingOrderNo, deliveryDate, checkOrderNo
              FROM pending_report
              WHERE qty > 0`;
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
//15-12-2023
app.get('/get_stock_items_for_sale', (req, res) => {
  try {
    const orderNumbersParam = req.query.orderNumbers;

    if (!orderNumbersParam) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order numbers not provided.' });
    }

    const orderNumbers = orderNumbersParam.split(',');
    const placeholders = orderNumbers.map(() => '?').join(', ');

    const query = `
      SELECT
        p.custName,
        p.custCode,
        p.orderNo,
        p.deliveryType,
        p.itemGroup,
        p.itemName,
        CONCAT(DATE_FORMAT(p.date, '%d-%m-'), SUBSTRING(YEAR(p.date), 3)) as date,
        p.qty,
        i.rate,
        i.unit,
        i.gst,
        i.hsnCode,  -- Added hsnCode here
        s.qty AS stock_qty,
        CASE
            WHEN s.qty < p.qty THEN p.qty - s.qty
            ELSE NULL
        END AS qty_to_order
      FROM
        purchase_order p
      LEFT JOIN
        item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
      LEFT JOIN
        stock s ON s.itemGroup = p.itemGroup AND s.itemName = p.itemName
      WHERE
        (s.qty IS NOT NULL AND s.qty < p.qty) AND
        p.orderNo IN (${placeholders})
      ;
    `;

    db.query(query, orderNumbers, (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});



app.get('/get_stock_items_for_sale_pending', (req, res) => {
    try {
        const pendingOrderNosParam = req.query.pendingOrderNos;

        if (!pendingOrderNosParam) {
            return res.status(400).json({ error: 'Bad Request', message: 'pendingOrderNo numbers not provided.' });
        }

        const pendingOrderNos = pendingOrderNosParam.split(',');

        const query = `
            SELECT
                p.custCode,
                p.custName,
                p.deliveryType,
                p.itemGroup,
                p.itemName,
                SUM(CAST(p.qty AS SIGNED)) AS t_qty,
                p.pincode,
                CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) AS date,
                p.orderNo,
                p.custAddress,
                p.custMobile,
                p.pendingOrderNo,
                p.deliveryDate,
                p.checkOrderNo,
                p.individualOrderNo,
                p.orderDate,
                i.rate,
                i.unit,
                i.gst,
                i.hsnCode,  -- Added hsnCode here
                COALESCE(s.stock_qty, 0) AS stock_qty,
                CASE
                    WHEN COALESCE(s.stock_qty, 0) < SUM(CAST(p.qty AS SIGNED)) THEN COALESCE(s.stock_qty, 0)
                    ELSE SUM(CAST(p.qty AS SIGNED))
                END AS qty_available,
                (SUM(CAST(p.qty AS SIGNED)) - CASE WHEN COALESCE(s.stock_qty, 0) < SUM(CAST(p.qty AS SIGNED)) THEN COALESCE(s.stock_qty, 0) ELSE SUM(CAST(p.qty AS SIGNED)) END) AS qty
            FROM (
                SELECT
                    custCode,
                    custName,
                    deliveryType,
                    itemGroup,
                    itemName,
                    qty,
                    pincode,
                    orderNo,
                    custAddress,
                    custMobile,
                    pendingOrderNo,
                    deliveryDate,
                    checkOrderNo,
                    individualOrderNo,
                    orderDate
                FROM
                    pending_report
                WHERE
                    pendingOrderNo IN (?)
            ) p
            LEFT JOIN (
                SELECT
                    itemGroup,
                    itemName,
                    COALESCE(SUM(CAST(qty AS SIGNED)), 0) AS stock_qty
                FROM
                    stock
                GROUP BY
                    itemGroup,
                    itemName
            ) s ON p.itemGroup = s.itemGroup AND p.itemName = s.itemName
            LEFT JOIN item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
            GROUP BY
                p.custCode,
                p.custName,
                p.deliveryType,
                p.itemGroup,
                p.itemName,
                p.pincode,
                p.orderNo,
                p.custAddress,
                p.custMobile,
                p.pendingOrderNo,
                p.deliveryDate,
                p.checkOrderNo,
                p.individualOrderNo,
                p.orderDate,
                i.rate,
                i.unit,
                i.gst,
                i.hsnCode,  -- Also grouped by hsnCode
                s.stock_qty
            HAVING
                qty > 0 ;
        `;
        db.query(query, [pendingOrderNos], (error, results) => {
            if (error) {
                console.error('4312 Error executing query:', error);
                res.status(500).json({ error: '4312 Internal Server Error', message: error.message });
            } else {
                res.json(results);
            }
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
});
   app.post('/nonsales_insert', (req, res) => {
  const { dataToInsertPurchaseReturnItem } = req.body;
    const sql = 'INSERT INTO nonsaleorder SET ?';
  db.query(sql, [dataToInsertPurchaseReturnItem], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/get_Noninvoice_no', (req, res) => {
  const sql = 'SELECT * FROM nonsaleorder order by invoiceNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/nonsales_item_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  //const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  const sql = `SELECT * FROM nonsaleorder WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.post('/pending_insert_unavailable', (req, res) => {
  const { datapendingInsertunavailablestock } = req.body;
    const sql = 'INSERT INTO pending_report SET ?';
  db.query(sql, [datapendingInsertunavailablestock], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/fetch_checkOrderNo', (req, res) => {
   try {
     const pendingOrderNosParam = req.query.pendingOrderNos;

     if (!pendingOrderNosParam) {
       return res.status(400).json({ error: 'Bad Request', message: 'pendingOrderNo numbers not provided.' });
     }

     const pendingOrderNos = pendingOrderNosParam.split(',');

     const query = `
           SELECT
                     COALESCE(
                       GROUP_CONCAT(DISTINCT
                         CASE
                           WHEN individualOrderNo IS NULL OR individualOrderNo = '' THEN orderNo
                           ELSE individualOrderNo
                         END
                         ORDER BY pendingOrderNo
                         SEPARATOR ','
                       ), '') AS result
                   FROM pending_report
                   WHERE pendingOrderNo IN (?) AND qty<>0;
        `;
     db.query(query, [pendingOrderNos], (error, results) => {
       if (error) {
         console.error('4312 Error executing query:', error);
         res.status(500).json({ error: '4312 Internal Server Error', message: error.message });
       } else {
         res.json(results);
       }
     });
   } catch (error) {
     console.error('Error:', error);
     res.status(500).json({ error: 'Internal Server Error', message: error.message });
   }
 });
app.get('/get_pending_items', (req, res) => {
    try {
        const pendingOrderNosParam = req.query.pendingOrderNos;

        if (!pendingOrderNosParam) {
            return res.status(400).json({ error: 'Bad Request', message: 'pendingOrderNo numbers not provided.' });
        }

        const pendingOrderNos = pendingOrderNosParam.split(',');
        const placeholders = pendingOrderNos.map(() => '?').join(', ');

        const query = `
            SELECT
                p.custCode,
                p.custName,
                p.deliveryType,
                p.itemGroup,
                p.itemName,
                SUM(CAST(p.qty AS SIGNED)) AS t_qty,
                p.pincode,
                CONCAT(DATE_FORMAT(p.orderDate, '%d-%m-'), SUBSTRING(YEAR(p.orderDate), 3)) AS date,
                p.orderNo,
                p.custAddress,
                p.custMobile,
                p.pendingOrderNo,
                p.deliveryDate,
                p.checkOrderNo,
                p.individualOrderNo,
                p.orderDate,
                i.rate,
                i.unit,
                i.gst,
                i.hsnCode,  -- Added hsnCode here
                COALESCE(s.stock_qty, 0) AS stock_qty,
                CASE
                    WHEN COALESCE(s.stock_qty, 0) < SUM(CAST(p.qty AS SIGNED)) THEN COALESCE(s.stock_qty, 0)
                    ELSE SUM(CAST(p.qty AS SIGNED))
                END AS qty
            FROM (
                SELECT
                    custCode,
                    custName,
                    deliveryType,
                    itemGroup,
                    itemName,
                    qty,
                    pincode,
                    orderNo,
                    custAddress,
                    custMobile,
                    pendingOrderNo,
                    deliveryDate,
                    checkOrderNo,
                    individualOrderNo,
                    orderDate
                FROM
                    pending_report
                WHERE
                    pendingOrderNo IN (${placeholders})
            ) p
            LEFT JOIN (
                SELECT
                    itemGroup,
                    itemName,
                    COALESCE(SUM(CAST(qty AS SIGNED)), 0) AS stock_qty
                FROM
                    stock
                GROUP BY
                    itemGroup,
                    itemName
            ) s ON p.itemGroup = s.itemGroup AND p.itemName = s.itemName
            LEFT JOIN item i ON p.itemGroup = i.itemGroup AND p.itemName = i.itemName
            GROUP BY
                p.custCode,
                p.custName,
                p.deliveryType,
                p.itemGroup,
                p.itemName,
                p.pincode,
                p.orderNo,
                p.custAddress,
                p.custMobile,
                p.pendingOrderNo,
                p.deliveryDate,
                p.checkOrderNo,
                p.individualOrderNo,
                p.orderDate,
                i.rate,
                i.unit,
                i.gst,
                i.hsnCode,  -- Also grouped by hsnCode
                s.stock_qty
            HAVING
                qty > 0 AND stock_qty > 0;
        `;

        db.query(query, pendingOrderNos, (error, results) => {
            if (error) {
                console.error('4312 Error executing query:', error);
                res.status(500).json({ error: '4312 Internal Server Error', message: error.message });
            } else {
                res.json(results);
            }
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
});
app.get('/get_pending_report_orderNo', (req, res) => {
  const orderNo = req.query.orderNo;

  // Assuming 'pending_report' is the name of your table
  const sql = `SELECT * FROM pending_report WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      console.error('Error fetching pending report details:', err);
      res.status(500).json({ error: 'Error fetching pending report details' });
    } else {
      console.log('Pending report details fetched successfully');
      res.status(200).json(result);
    }
  });
});
app.get('/pending_sale_item_view', (req, res) => {
  const pendingOrderNo = req.query.pendingOrderNo;

  const sql = `SELECT * FROM pending_report WHERE pendingOrderNo = ?`;

  db.query(sql, [pendingOrderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});



//good
/*app.post('/updateRawMaterial_daily_work', async (req, res) => {
  const { prodName, id, totalweight, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET  totalweight =totalweight - ?, modifyDate = ? WHERE prodName = ? AND id = ?';
  const values = [totalweight, modifyDate, prodName, id];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});*/

app.post('/updateRawMaterial_daily_work', async (req, res) => {
  const { prodName, id, sNo, totalweight, modifyDate } = req.body;

  const sqlUpdate = 'UPDATE raw_material SET totalweight = totalweight - ?, modifyDate = ? WHERE prodName = ? AND id = ? AND sNo = ?';
  const valuesUpdate = [totalweight, modifyDate, prodName, id, sNo];

  db.query(sqlUpdate, valuesUpdate, async (err, updateResult) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error: Unable to update raw_material entry');
    } else {
      console.log('Update Result:', updateResult);

      if (updateResult.affectedRows === 0) {
        console.log('No rows were updated. Check if the provided data matches any existing records.');
        res.status(400).send('Bad Request: No rows were updated.');
        return;
      }

      // Check if totalweight is 0 after the update and delete the row if true
      const deleteSql = 'DELETE FROM raw_material WHERE prodName = ? AND id = ? AND sNo = ? AND totalweight = 0';
      const deleteValues = [prodName, id, sNo];

      db.query(deleteSql, deleteValues, (deleteErr, deleteResult) => {
        if (deleteErr) {
          console.error('Error deleting row with totalweight 0:', deleteErr);
          res.status(500).send('Internal Server Error: Unable to delete row with totalweight 0');
        } else {
          console.log('Delete Result:', deleteResult);
          res.send('raw_material updated successfully');
        }
      });
    }
  });
});


app.get('/get_daily_work_status', (req, res) => {
 const sql = 'SELECT * FROM daily_work_status';
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

//27-12-2023

app.post('/daily_work_status', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO daily_work_status SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});








//good
app.get('/fetch_daily_Work_status', (req, res) => {
  const { shiftType, machName, desiredDate } = req.query;

  const sql =  ` SELECT
                    machName,
                    shiftType,
                    assOne AS winding_assOne,
                    emp_code1 AS winding_oPempcode1,
                    asstwo AS winding_asstwo,
                    emp_code2 AS winding_empcode1,
                    opOneName AS winding_opOneName,
                    emp_code3 AS winding_empcode2,
                    NULL AS finishing_assOne,
                    NULL AS finishing_empcode1,
                    NULL AS finishing_opOneName,
                    NULL AS finishing_empcode2,
                    NULL AS printing_assOne,
                    NULL AS printing_empcode1,
                    NULL AS printing_opOneName,
                    NULL AS printing_empcode2
                FROM winding_entry
                WHERE shiftType = '${shiftType}' AND machName = '${machName}'AND '${desiredDate}' BETWEEN fromDate AND toDate

                UNION

                SELECT
                    machName,
                    shiftType,
                    assOne AS finishing_assOne,
                    emp_code1 AS finishing_empcode1,
                    opOneName AS finishing_opOneName,
                    emp_code2 AS finishing_empcode2,
                    NULL AS winding_assOne,
                    NULL AS winding_empcode1,
                    NULL AS winding_asstwo,
                    NULL AS winding_empcode2,
                    NULL AS winding_opOneName,
                    NULL AS winding_oPempcode1,
                    NULL AS printing_assOne,
                    NULL AS printing_empcode1,
                    NULL AS printing_opOneName,
                    NULL AS printing_empcode2
                FROM finishing_entry
                WHERE shiftType = '${shiftType}'  AND machName = '${machName}'AND '${desiredDate}' BETWEEN fromDate AND toDate

                UNION

                SELECT
                    machName,
                    shiftType,
                    assOne AS printing_assOne,
                    emp_code1 AS printing_empcode1,
                    opOneName AS printing_opOneName,
                    emp_code2 AS printing_empcode2,
                    NULL AS winding_assOne,
                    NULL AS winding_empcode1,
                    NULL AS winding_asstwo,
                    NULL AS winding_empcode2,
                    NULL AS winding_opOneName,
                    NULL AS winding_oPempcode1,
                    NULL AS finishing_assOne,
                    NULL AS finishing_empcode1,
                    NULL AS finishing_opOneName,
                    NULL AS finishing_empcode2
                FROM printing_entry
                WHERE shiftType = '${shiftType}' AND machName = '${machName}'AND '${desiredDate}' BETWEEN fromDate AND toDate
                   `;

  db.query(sql, [shiftType, machName,desiredDate], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});
//good






/*app.get('/fetch_daily_Work_status', (req, res) => {
  const { shiftType, machName, desiredDate } = req.query;

  const sql =  `     SELECT
                     machName,
                     shiftType,
                     CASE WHEN AltEmp = 'Yes' AND assOne IS NOT NULL THEN assOne ELSE NULL END AS winding_assOne,
                     CASE WHEN AltEmp = 'Yes' AND emp_code1 IS NOT NULL THEN emp_code1 ELSE NULL END AS winding_oPempcode1,
                     CASE WHEN AltEmp = 'Yes' AND asstwo IS NOT NULL THEN asstwo ELSE NULL END AS winding_asstwo,
                     CASE WHEN AltEmp = 'Yes' AND emp_code2 IS NOT NULL THEN emp_code2 ELSE NULL END AS winding_empcode1,
                     CASE WHEN AltEmp = 'Yes' AND opOneName IS NOT NULL THEN opOneName ELSE NULL END AS winding_opOneName,
                     CASE WHEN AltEmp = 'Yes' AND emp_code3 IS NOT NULL THEN emp_code3 ELSE NULL END AS winding_empcode2,
                     NULL AS finishing_assOne,
                     NULL AS finishing_empcode1,
                     NULL AS finishing_opOneName,
                     NULL AS finishing_empcode2,
                     NULL AS printing_assOne,
                     NULL AS printing_empcode1,
                     NULL AS printing_opOneName,
                     NULL AS printing_empcode2
                 FROM winding_entry
                 WHERE
                     (shiftType = '${shiftType}' AND machName = '${machName}' AND '${desiredDate}' BETWEEN fromDate AND toDate)
                     AND (AltEmp = 'Yes' AND (assOne IS NOT NULL OR emp_code1 IS NOT NULL OR asstwo IS NOT NULL OR emp_code2 IS NOT NULL OR opOneName IS NOT NULL OR emp_code3 IS NOT NULL))

                 UNION

                 SELECT
                     machName,
                     shiftType,
                     CASE WHEN AltEmp = 'Yes' AND assOne IS NOT NULL THEN assOne ELSE NULL END AS finishing_assOne,
                     CASE WHEN AltEmp = 'Yes' AND emp_code1 IS NOT NULL THEN emp_code1 ELSE NULL END AS finishing_empcode1,
                     CASE WHEN AltEmp = 'Yes' AND opOneName IS NOT NULL THEN opOneName ELSE NULL END AS finishing_opOneName,
                     CASE WHEN AltEmp = 'Yes' AND emp_code2 IS NOT NULL THEN emp_code2 ELSE NULL END AS finishing_empcode2,
                     NULL AS winding_assOne,
                     NULL AS winding_empcode1,
                     NULL AS winding_asstwo,
                     NULL AS winding_empcode2,
                     NULL AS winding_opOneName,
                     NULL AS winding_oPempcode1,
                     NULL AS printing_assOne,
                     NULL AS printing_empcode1,
                     NULL AS printing_opOneName,
                     NULL AS printing_empcode2
                 FROM finishing_entry
                 WHERE
                     (shiftType = '${shiftType}' AND machName = '${machName}' AND '${desiredDate}' BETWEEN fromDate AND toDate)
                     AND (AltEmp = 'Yes' AND (assOne IS NOT NULL OR emp_code1 IS NOT NULL OR opOneName IS NOT NULL OR emp_code2 IS NOT NULL))

                 UNION

                 SELECT
                     machName,
                     shiftType,
                     CASE WHEN AltEmp = 'Yes' AND assOne IS NOT NULL THEN assOne ELSE NULL END AS printing_assOne,
                     CASE WHEN AltEmp = 'Yes' AND emp_code1 IS NOT NULL THEN emp_code1 ELSE NULL END AS printing_empcode1,
                     CASE WHEN AltEmp = 'Yes' AND opOneName IS NOT NULL THEN opOneName ELSE NULL END AS printing_opOneName,
                     CASE WHEN AltEmp = 'Yes' AND emp_code2 IS NOT NULL THEN emp_code2 ELSE NULL END AS printing_empcode2,
                     NULL AS winding_assOne,
                     NULL AS winding_empcode1,
                     NULL AS winding_asstwo,
                     NULL AS winding_empcode2,
                     NULL AS winding_opOneName,
                     NULL AS winding_oPempcode1,
                     NULL AS finishing_assOne,
                     NULL AS finishing_empcode1,
                     NULL AS finishing_opOneName,
                     NULL AS finishing_empcode2
                 FROM printing_entry
                 WHERE
                     (shiftType = '${shiftType}' AND machName = '${machName}' AND '${desiredDate}' BETWEEN fromDate AND toDate)
                     AND (AltEmp = 'Yes' AND (assOne IS NOT NULL OR emp_code1 IS NOT NULL OR opOneName IS NOT NULL OR emp_code2 IS NOT NULL))`;

  db.query(sql, [shiftType, machName,desiredDate], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});*/

app.get('/get_machinename_finishing', (req, res) => {
  const machineType = req.query.machineType;

  const sql = `SELECT  machineName FROM machine where machineType= ?`;

  db.query(sql, [machineType], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});
app.post('/update_return_Qty_to_purchase', (req, res) => {
  const { invoiceNo,returnQty,prodCode,prodName } = req.body;

  const sql ='UPDATE purchase SET returnQty = ? WHERE invoiceNo = ? AND prodCode = ?AND prodName = ?';

  db.query(sql, [invoiceNo,returnQty,prodCode,prodName], (err, result) => {
    if (err) {
      console.error('Error updating field: ' + err.stack);
      res.status(500).send('Error updating field');
    } else {
      console.log('Field updated successfully');
      res.send('Field updated successfully');
    }
  });
});
app.get('/pendingPO_fetch', (req, res) => {
  const sql = 'SELECT * FROM pending_po order by pendingOrderNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/pending_insert_PO', (req, res) => {
  const { datapendingInsert } = req.body;
    const sql = 'INSERT INTO pending_po SET ?';
  db.query(sql, [datapendingInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});


app.get('/fetch__pending_po_datas', (req, res) => {
  const sql = 'SELECT * FROM pending_po ORDER BY pendingOrderNo DESC';
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
app.get('/get_pending_po_item', (req, res) => {
  const pendingOrderNo = req.query.pendingOrderNo;

  const sql = `SELECT p.prodCode, p.prodName, p.qty, p.deliveryDate, p.supCode, p.poNo, p.date, p.invoiceNo, i.unit
               FROM pending_po p
               LEFT JOIN prodcode_entry i ON p.prodCode = i.prodCode AND p.prodName = i.prodName
               WHERE p.qty<>0 AND pendingOrderNo = ?`;

  db.query(sql, [pendingOrderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/get_po_pending_report', (req, res) => {
 const sql = `SELECT *
              FROM pending_po
              WHERE qty > 0`;
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
app.get('/pending_po_item_view', (req, res) => {
  const pendingOrderNo = req.query.pendingOrderNo;

  const sql = `SELECT * FROM pending_po WHERE pendingOrderNo = ?  AND qty <>0`;

  db.query(sql, [pendingOrderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/nonsales_item_view', (req, res) => {
     const invoiceNo = req.query.invoiceNo;

     //const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
     const sql = `SELECT * FROM nonsaleorder WHERE invoiceNo = ?`;

     db.query(sql, [invoiceNo], (err, result) => {
       if (err) {
         throw err;
       }
       res.json(result);
     });
   });
   app.get('/nonsales_item_view', (req, res) => {
     const invoiceNo = req.query.invoiceNo;

     //const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
     const sql = `SELECT * FROM nonsaleorder WHERE invoiceNo = ?`;

     db.query(sql, [invoiceNo], (err, result) => {
       if (err) {
         throw err;
       }
       res.json(result);
     });
   });
   app.get('/get_non_sales_order_entry', (req, res) => {

    const sql = 'SELECT * FROM nonsaleorder';
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
   app.get('/production_get_report', (req, res) => {
      const sql = 'SELECT * FROM production_entry';
      db.query(sql, (err, results) => {
        if (err) {
          console.error('Error fetching data:', err);
          res.status(500).json({ error: 'Error fetching data' });
        } else {
          res.status(200).json(results);
        }
      });
    });




//end bhuvana


//Employee
app.get('/empID', (req, res) => {
  const sql = 'SELECT * FROM employee order by empID desc limit 1'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/employee/:empID', (req, res) => {
  const empID = req.params.empID;

  const query = 'SELECT * FROM employee WHERE empID = ?';

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



app.post('/employee', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO employee SET ?'; // Modify to your table name
  db.query(sql, [dataToInsert], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
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


app.get('/getemplyeeview', (req, res) => {
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




app.post('/attandance_insert', (req, res) => {
  const { dataToInsertSupItem3 } = req.body;
   console.log('Received data:', dataToInsertSupItem3);// Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO attendance SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertSupItem3], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.post('/insert_attendance', (req, res) => {
  const { dataToInsertSupItem2 } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO attendance SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertSupItem2], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//7//12

app.post('/atten_entry', (req, res) => {
  const dataToInsert = req.body.dataToInsert;

  // Perform the MySQL insert query
  db.query('INSERT INTO attendance SET ?', dataToInsert, (err, results) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//9/12
app.get('/quto_item_view', (req, res) => {
  const quotNo = req.query.quotNo;
  const sql = `SELECT * FROM quotation WHERE quotNo = ?`;
  db.query(sql, [quotNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
//10//12//2023
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


app.post('/upload', upload.single('image'), (req, res) => {
  const imageData = req.file.buffer;

  pool.query('INSERT INTO images (image_data) VALUES (?)', [imageData], (err, results) => {
    if (err) {
      console.error('Error inserting image into database:', err);
      res.status(500).send('Internal Server Error');
    } else {
      console.log('Image inserted into database');
      res.status(200).send('Image uploaded successfully');
    }
  });
});

app.get('/get_fromtodate', (req, res) => {
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;

  const sql = `SELECT emp_code FROM shift  WHERE fromDate = ? AND toDate = ? `;

  // Logging parameters for debugging
  console.log('fromDate:', fromDate);
  console.log('toDate:', toDate);


  db.query(sql, [fromDate, toDate], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json({ unit: null });
    } else {
      res.json(result[0]);
    }
  });
});

app.get('/check_empid_exists', (req, res) => {
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;
  const emp_code = req.query.emp_code;

  const sql = `SELECT COUNT(*) AS count FROM shift WHERE fromDate = ? AND toDate = ? AND emp_code = ?`;

  db.query(sql, [fromDate, toDate, emp_code], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }

    const count = result[0].count;
    res.json({ exists: count > 0 });
  });
});

//winding/finishing/printing
app.get('/get_machinename_print', (req, res) => {
  const machineType = req.query.machineType;
//  const toDate = req.query.toDate;
//  const shiftType = req.query.shiftType;

  const sql = `SELECT  machineName FROM machine where machineType='Printing';`;

  db.query(sql, [machineType], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});

app.get('/get_printing_code', (req, res) => {
  const sql = 'SELECT * FROM printing_entry order by printing_ID desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.post('/Printing_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO printing_entry SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/winding_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO winding_entry SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.post('/winding_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO winding_entry SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});


///finishing code auto increment

app.get('/get_finishing_code', (req, res) => {
  const sql = 'SELECT * FROM finishing_entry order by finishing_ID desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
/// winding get
app.get('/winding_entry_duplicatecheck', (req, res) => {
  const sql = 'SELECT * FROM winding_entry';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
/// winding get
app.get('/winding_Id_fetch', (req, res) => {
  const winding_ID = req.query.winding_ID;

  const sql = `SELECT * FROM winding_entry where winding_ID = ?`;

  db.query(sql, [winding_ID], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
/// get machine name
app.get('/get_machinename', (req, res) => {
  const machineType = req.query.machineType;
//  const toDate = req.query.toDate;
//  const shiftType = req.query.shiftType;

  const sql = `SELECT  machineName FROM machine where machineType='Winding';`;

  db.query(sql, [machineType], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});
///fetch printing machine name
app.get('/get_machinename_printing', (req, res) => {
  const machineType = req.query.machineType;
//  const toDate = req.query.toDate;
//  const shiftType = req.query.shiftType;

  const sql = `SELECT  machineName FROM machine where machineType='Finishing';`;

  db.query(sql, [machineType], (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});

/// Winiding Entry based on get values New
/*
app.get('/get_fromtodate2', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.first_name,
            vkcones.shift.shiftType,
            vkcones.shift.emp_code
        FROM
            vkcones.shift
        WHERE
            vkcones.shift.emp_code NOT IN (
                SELECT emp_code1
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate = ? AND vkcones.winding_entry.toDate = ?
                UNION
                SELECT emp_code2
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate = ? AND vkcones.winding_entry.toDate = ?
                UNION
                SELECT emp_code3
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate = ? AND vkcones.winding_entry.toDate = ?
            )
            AND vkcones.shift.fromdate >= ?
            AND vkcones.shift.todate <= ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate, shiftType];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});
*/

/// printing Entry New
app.get('/get_fromtodate3', (req, res) => {
  const shiftdate = req.query.shiftdate;
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;
  const shiftType = req.query.shiftType;

  const sql = `
    SELECT
      vkcones.shift.first_name,
      vkcones.shift.shiftType,
      vkcones.shift.emp_code
    FROM
      vkcones.shift
    WHERE
      vkcones.shift.emp_code NOT IN (
        SELECT emp_code1
        FROM vkcones.finishing_entry
        WHERE vkcones.finishing_entry.fromDate <= ? AND vkcones.finishing_entry.toDate >= ?
        UNION
        SELECT emp_code2
        FROM vkcones.finishing_entry
        WHERE vkcones.finishing_entry.fromDate <= ? AND vkcones.finishing_entry.toDate >= ?
      )
      AND vkcones.shift.emp_code NOT IN (
        SELECT DISTINCT emp_code1
        FROM vkcones.printing_entry
        WHERE vkcones.printing_entry.fromDate <= ? AND vkcones.printing_entry.toDate >= ?
        UNION
        SELECT DISTINCT emp_code2
        FROM vkcones.printing_entry
        WHERE vkcones.printing_entry.fromDate <= ? AND vkcones.printing_entry.toDate >= ?
      )
      AND vkcones.shift.fromdate = ?
      AND vkcones.shift.todate = ?
      AND vkcones.shift.shiftType = ?;
  `;

  const params = [fromDate, toDate,fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate, shiftType];

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }

    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});

/// finishing Entry New
app.get('/get_fromtodate4', (req, res) => {
  const shiftdate = req.query.shiftdate;
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;
  const shiftType = req.query.shiftType;

  const sql = `
    SELECT
      vkcones.shift.first_name,
      vkcones.shift.shiftType,
      vkcones.shift.emp_code
    FROM
      vkcones.shift
    WHERE
      vkcones.shift.emp_code NOT IN (
        SELECT emp_code1
        FROM vkcones.finishing_entry
        WHERE vkcones.finishing_entry.fromDate <= ? AND vkcones.finishing_entry.toDate >= ?
        UNION
        SELECT emp_code2
        FROM vkcones.finishing_entry
        WHERE vkcones.finishing_entry.fromDate <= ? AND vkcones.finishing_entry.toDate >= ?
      )
      AND vkcones.shift.emp_code NOT IN (
        SELECT DISTINCT emp_code1
        FROM vkcones.printing_entry
        WHERE vkcones.printing_entry.fromDate <= ? AND vkcones.printing_entry.toDate >= ?
        UNION
        SELECT DISTINCT emp_code2
        FROM vkcones.printing_entry
        WHERE vkcones.printing_entry.fromDate <= ? AND vkcones.printing_entry.toDate >= ?
      )
      AND vkcones.shift.fromdate = ?
      AND vkcones.shift.todate = ?
      AND vkcones.shift.shiftType = ?;
  `;

  const params = [fromDate, toDate,fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate, shiftType];

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).send('Internal Server Error');
      return;
    }

    // Check if the result set is empty
    if (result.length === 0) {
      res.json([]);
    } else {
      res.json(result);
    }
  });
});


///winding get report
/*
app.get('/winding_entry_get_report', (req, res) => {
  const sql = 'SELECT id,machName,assOne,assTwo,opOneName,shiftType,date FROM winding_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
*/

///--------Finshing------------------
//finishing_entry
app.post('/finishing_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO finishing_entry SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
//22/12/23
//printing report
app.get('/printing_entry_get_report', (req, res) => {
  const sql = 'SELECT * FROM printing_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/finishing_entry_get_report', (req, res) => {
  const sql = 'SELECT * FROM finishing_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


/// For Update Winding Update
app.post('/winding_update', (req, res) => {
  const { dataToInsertSup } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO winding_entry SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertSup], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

/// For Printing Update
app.post('/Printing_update', (req, res) => {
  const { dataToInsertSup } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO printing_entry SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertSup], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

/// For Finishing Update
app.post('/Finishing_update', (req, res) => {
  const { dataToInsertSup } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO finishing_entry SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertSup], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

/// For Winding Edit View
/*
app.get('/get_fromtodate20', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.alterEmp,
            vkcones.shift.shiftType,
            vkcones.shift.alterEmpID
        FROM
            vkcones.shift
        WHERE
                vkcones.shift.alterEmpID NOT IN (
                        SELECT emp_code1
                        FROM vkcones.winding_entry
                        WHERE vkcones.winding_entry.fromDate = ?AND vkcones.winding_entry.toDate = ?
                        UNION
                        SELECT emp_code2
                        FROM vkcones.winding_entry
                        WHERE vkcones.winding_entry.fromDate = ? AND vkcones.winding_entry.toDate = ?
                        UNION
                        SELECT emp_code3
                        FROM vkcones.winding_entry
                        WHERE vkcones.winding_entry.fromDate = ? AND vkcones.winding_entry.toDate = ?
                    )
           AND vkcones.shift.fromdate = ?
            AND vkcones.shift.todate = ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [fromDate, toDate,fromDate, toDate,fromDate, toDate,fromDate, toDate, shiftType];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});
*/

/// For prniting Edit View
app.get('/get_fromtodate21', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.alterEmp,
            vkcones.shift.shiftType,
            vkcones.shift.alterEmpID
        FROM
            vkcones.shift
        WHERE
            vkcones.shift.alterEmpID NOT IN (
                SELECT DISTINCT emp_code1
                FROM vkcones.printing_entry
                WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                UNION
                SELECT DISTINCT emp_code2
                FROM vkcones.printing_entry
                WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
            )
            AND vkcones.shift.alterEmpID NOT IN (
                SELECT emp_code1
                FROM vkcones.finishing_entry
                WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                UNION
                SELECT emp_code2
                FROM vkcones.finishing_entry
                WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
            )
            AND vkcones.shift.fromdate >= ?
            AND vkcones.shift.todate <= ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [
        fromDate, toDate, fromDate, toDate, fromDate, toDate,
        fromDate, toDate, fromDate, toDate, shiftType
    ];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});
/// For finishing Edit View
app.get('/get_fromtodate22', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.alterEmp,
            vkcones.shift.shiftType,
            vkcones.shift.alterEmpID
        FROM
            vkcones.shift
        WHERE
            vkcones.shift.alterEmpID NOT IN (
                SELECT DISTINCT emp_code1
                FROM vkcones.printing_entry
                WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate >= ?
                UNION
                SELECT DISTINCT emp_code2
                FROM vkcones.printing_entry
                WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
            )
            AND vkcones.shift.alterEmpID NOT IN (
                SELECT emp_code1
                FROM vkcones.finishing_entry
                WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                UNION
                SELECT emp_code2
                FROM vkcones.finishing_entry
                WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
            )
            AND vkcones.shift.fromdate <= ?
            AND vkcones.shift.todate >= ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [
        fromDate, toDate, fromDate, toDate, fromDate, toDate,
        fromDate, toDate, fromDate, toDate, shiftType
    ];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});


/// Winding Finishing Prnitng Other Worker Entry All New files 05-01-2023
app.get('/printing_entry_duplicatecheck', (req, res) => {
  const sql = 'SELECT * FROM printing_entry';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/finishing_entry_duplicatecheck', (req, res) => {
  const sql = 'SELECT * FROM finishing_entry';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
/// Tab Controller
app.get('/get_fromtodate2', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.first_name,
            vkcones.shift.shiftType,
            vkcones.shift.emp_code
        FROM
            vkcones.shift
        WHERE
            vkcones.shift.emp_code NOT IN (
                SELECT emp_code1
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                UNION
                SELECT emp_code2
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                UNION
                SELECT emp_code3
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
            )
            AND vkcones.shift.emp_code NOT IN (
                    SELECT DISTINCT emp_code1
                    FROM vkcones.printing_entry
                    WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                    UNION
                    SELECT DISTINCT emp_code2
                    FROM vkcones.printing_entry
                    WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                  )
            AND  vkcones.shift.emp_code NOT IN (
                         SELECT emp_code1
                         FROM vkcones.finishing_entry
                         WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                         UNION
                         SELECT emp_code2
                         FROM vkcones.finishing_entry
                         WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                       )
              AND  vkcones.shift.emp_code NOT IN (
                                     SELECT emp_code1
                                     FROM vkcones.other_working_entry
                                     WHERE vkcones.other_working_entry.fromDate >= ? AND vkcones.other_working_entry.toDate <= ?
                    )


            AND vkcones.shift.fromdate <= ?
            AND vkcones.shift.todate >= ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [fromDate, toDate,fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate,fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate, shiftType];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});
/// Winding View
app.get('/get_fromtodate20', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.alterEmp,
            vkcones.shift.shiftType,
            vkcones.shift.alterEmpID
        FROM
            vkcones.shift
        WHERE
                vkcones.shift.alterEmpID NOT IN (
                        SELECT emp_code1
                        FROM vkcones.winding_entry
                        WHERE vkcones.winding_entry.fromDate >= ?AND vkcones.winding_entry.toDate <= ?
                        UNION
                        SELECT emp_code2
                        FROM vkcones.winding_entry
                        WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                        UNION
                        SELECT emp_code3
                        FROM vkcones.winding_entry
                        WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                    )
           AND vkcones.shift.fromdate <= ?
            AND vkcones.shift.todate >= ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [fromDate, toDate,fromDate, toDate,fromDate, toDate,fromDate, toDate, shiftType];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});


app.get('/other_working_entry_code', (req, res) => {
  const sql = 'SELECT * FROM other_working_entry order by others_working_ID desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/other_working_entry', (req, res) => {
  const { dataToInsert } = req.body;

  const sql = 'INSERT INTO other_working_entry SET ?';

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err); // Log the error
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.get('/other_working_entry_report', (req, res) => {
  const sql = 'SELECT * FROM other_working_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/other_working_entry_update', (req, res) => {
  const { dataToInsertSup } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO other_working_entry SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertSup], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//07//01//2024

/*app.post('/updateRawMaterialdailywork', async (req, res) => {
  const { prodName, qty, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET  qty = qty - ?, modifyDate = ? WHERE  prodName = ?';
  const values = [ qty, modifyDate, prodName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});*/

app.get('/getprodname', (req, res) => {
  const sql = 'SELECT DISTINCT prodName FROM raw_material ORDER BY prodName'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getgsm_printing', (req, res) => {
  const sql = 'SELECT gsm FROM winding_printing_production'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.post('/fetchweightinraw', (req, res) => {
  const { prodName } = req.body;
  const query = `SELECT totalweight FROM raw_material WHERE prodName = ?`;

  db.query(query, [prodName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ totalweight: results[0].totalweight });
    } else {
      res.json({ totalweight: '' }); // Return an empty string if no match found
    }
  });
});

/// Winding View Duplicate Check Prinitng View And Finishing View
app.get('/fetch_winding', (req, res) => {
  const sql = 'SELECT * FROM winding_entry';
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

app.get('/fetch_printing', (req, res) => {
  const sql = 'SELECT * FROM printing_entry';
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

app.get('/fetch_finishing', (req, res) => {
  const sql = 'SELECT * FROM finishing_entry';
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

app.get('/fetch_other_working_entry', (req, res) => {
  const sql = 'SELECT * FROM other_working_entry';
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
/// Other Worker Entry View
app.get('/get_combined', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.alterEmp,
            vkcones.shift.shiftType,
            vkcones.shift.alterEmpID
        FROM
            vkcones.shift
        WHERE
            (
                vkcones.shift.alterEmpID NOT IN (
                    SELECT emp_code1
                    FROM vkcones.winding_entry
                    WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                    UNION
                    SELECT emp_code2
                    FROM vkcones.winding_entry
                    WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                    UNION
                    SELECT emp_code3
                    FROM vkcones.winding_entry
                    WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                )

            AND (
                vkcones.shift.alterEmpID NOT IN (
                    SELECT DISTINCT emp_code1
                    FROM vkcones.printing_entry
                    WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                    UNION
                    SELECT DISTINCT emp_code2
                    FROM vkcones.printing_entry
                    WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                )
                AND vkcones.shift.alterEmpID NOT IN (
                    SELECT emp_code1
                    FROM vkcones.finishing_entry
                    WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                    UNION
                    SELECT emp_code2
                    FROM vkcones.finishing_entry
                    WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                )
                 AND vkcones.shift.alterEmpID NOT IN (
                                    SELECT emp_code1
                                    FROM vkcones.other_working_entry
                                    WHERE vkcones.other_working_entry.fromDate >= ? AND vkcones.other_working_entry.toDate <= ?
                                  )
                                AND vkcones.shift.fromdate <= ?
                                AND vkcones.shift.todate >= ?
                                AND vkcones.shift.shiftType = ?
                            )

            )
    `;

    const params = [
        fromDate, toDate, fromDate, toDate, fromDate, toDate,
        fromDate, toDate, fromDate, toDate,
        fromDate, toDate, fromDate, toDate,
        fromDate, toDate,
         fromDate, toDate, shiftType,
    ];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});

app.get('/other_entry_duplicatecheck', (req, res) => {
  const sql = 'SELECT * FROM other_working_entry';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.delete('/rawdelete/:prodName', (req, res) => {
  const { orderNo } = req.params;
  console.log('Received DELETE request for prodName:', prodName);

  const sql = 'DELETE weight FROM raw_material WHERE prodName = ?';
  const values = [prodName];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      console.log('Data deleted successfully');
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});


//11//01/24
app.post('/daily_work_status_entry', async (req, res) => {
  const data = req.body.dataToInsertorditem;

  // Step 1: Update existing rows
  const updateSql = `
    UPDATE daily_work_status
    SET productionQty = ?, extraproduction = ?
    WHERE machineType = ? AND createDate = ? AND shiftType = ?;
  `;

  try {
    const [updateResult] = await db.promise().query(updateSql, [
      data.productionQty,
      data.extraproduction,
      data.machineType,
      data.createDate,
      data.shiftType
    ]);

    console.log(`Updated ${updateResult.affectedRows} rows.`);

    // Step 2: Insert new row with all details
    const insertSql = 'INSERT INTO daily_work_status SET ?';

    const [insertResult] = await db.promise().query(insertSql, data);

    console.log('New row inserted successfully.');

    res.status(200).json({ message: 'Data updated and new row inserted successfully.' });
  } catch (err) {
    console.error('Error updating or inserting data:', err);
    res.status(500).json({ error: 'Error updating or inserting data' });
  }
});

//prodution winding production
app.get('/total_production_quantity', (req, res) => {
  const { machineType, shiftType, createDate, machineName } = req.query;

  const sql = 'SELECT SUM(productionQty) AS totalProductionQty FROM daily_work_status WHERE shiftType = ? AND machineType = ? AND createDate = ? AND machineName = ?';
  db.query(sql, [shiftType, machineType, createDate, machineName ], (err, result) => {
    if (err) {
      console.error('Error fetching total production quantity:', err);
      res.status(500).json({ error: 'Error fetching total production quantity' });
    } else {
      const totalProductionQty = result[0].totalProductionQty;
      console.log('Total Production Quantity:', totalProductionQty);
      res.status(200).json({ totalProductionQty });
    }
  });
});

app.post('/updateprinting_production', async (req, res) => {
  const { gsm, numofcones, status, date } = req.body;

  // Check if the gsm value with status "with printing" already exists
  const checkIfExistsSQL = 'SELECT COUNT(*) AS count FROM winding_printing_production WHERE gsm = ? AND status = "with printing"';
  const checkIfExistsValues = [gsm];

  db.query(checkIfExistsSQL, checkIfExistsValues, (checkErr, checkResult) => {
    if (checkErr) {
      console.error('Error checking if gsm exists:', checkErr);
      res.status(500).send('Internal Server Error');
      return;
    }

    const gsmCount = checkResult[0].count;

    if (gsmCount === 0) {
      // gsm with status "with printing" does not exist, insert a new entry
      const insertSQL = 'INSERT INTO winding_printing_production (gsm, numofcones, status, date) VALUES (?, ?, ?, ?)';
      const insertValues = [gsm, numofcones, status, date];

      db.query(insertSQL, insertValues, (insertErr, insertResult) => {
        if (insertErr) {
          console.error('Error inserting winding_printing_production entry:', insertErr);
          res.status(500).send('Internal Server Error');
        } else {
          res.send('winding_printing_production entry inserted successfully');
        }
      });
    } else {
      // gsm with status "with printing" already exists, update the numofcones
      const updateSQL = 'UPDATE winding_printing_production SET numofcones =  numofcones + ? , date = ? WHERE gsm = ? AND status = "with printing"';
      const updateValues = [numofcones, date, gsm];

      db.query(updateSQL, updateValues, (updateErr, updateResult) => {
        if (updateErr) {
          console.error('Error updating winding_printing_production entry:', updateErr);
          res.status(500).send('Internal Server Error');
        } else {
          res.send('winding_printing_production entry updated successfully');
        }
      });
    }
  });
});
app.post('/updatewithoutprinting_production', async (req, res) => {
  const { gsm, numofcones, status, date } = req.body;

  const sql = 'UPDATE winding_printing_production SET  numofcones = numofcones - ? , date = ? WHERE  gsm = ? AND status = "without printing"';
  const values = [ numofcones, date, gsm, status,];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});

//update winding_printing production
app.post('/updateproductiondailywork', async (req, res) => {
  const { gsm, itemGroup, itemName, numofcones, status, date } = req.body;
  // Check if a record with the specified GSM value already exists
  const checkSql = 'SELECT * FROM winding_printing_production WHERE itemGroup = ? AND itemName = ? AND gsm = ? AND status = ?';
  db.query(checkSql, [itemGroup, itemName, gsm, status], (checkErr, checkResult) => {
    if (checkErr) {
      console.error('Error checking if record exists:', checkErr);
      res.status(500).send('Internal Server Error');
    } else {
      if (checkResult.length > 0) {
        // Update the existing record
        const updateSql = 'UPDATE winding_printing_production SET numofcones = numofcones + ?, date = ? WHERE itemGroup = ? AND itemName = ? AND gsm = ? AND status = ?';
        const updateValues = [numofcones, date, itemGroup, itemName, gsm, status];
        db.query(updateSql, updateValues, (updateErr, updateResult) => {
          if (updateErr) {
            console.error('Error updating entry:', updateErr);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('Entry updated successfully');
          }
        });
      } else {
        // Insert a new record
        const insertSql = 'INSERT INTO winding_printing_production (date, gsm, itemGroup, itemName, numofcones, status) VALUES (?, ?, ?, ?, ?, ?)';
        const insertValues = [date, gsm, itemGroup, itemName, numofcones, status];

        db.query(insertSql, insertValues, (insertErr, insertResult) => {
          if (insertErr) {
            console.error('Error inserting new entry:', insertErr);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('New entry inserted successfully');
          }
        });
      }
    }
  });
});


//update_finishing_production
app.post('/update_finishing_dailywork', async (req, res) => {
  const { produce_pack, produce_totalcones, qty, totalcones, itemGroup, itemName, date } = req.body;
  // Check if a record with the specified GSM value already exists
  const checkSql = 'SELECT * FROM stock WHERE itemGroup = ? AND itemName = ?';
  db.query(checkSql, [itemGroup, itemName], (checkErr, checkResult) => {
    if (checkErr) {
      console.error('Error checking if record exists:', checkErr);
      res.status(500).send('Internal Server Error');
    } else {
      if (checkResult.length > 0) {
        // Update the existing record
        const updateSql = 'UPDATE stock SET produce_pack = produce_pack + ?, produce_totalcones = produce_totalcones + ?, qty = qty + ?, totalcones = totalcones + ?, date = ? WHERE itemGroup = ? AND itemName = ?';
        const updateValues = [produce_pack, produce_totalcones, qty, totalcones, date, itemGroup, itemName];
        db.query(updateSql, updateValues, (updateErr, updateResult) => {
          if (updateErr) {
            console.error('Error updating entry:', updateErr);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('Entry updated successfully');
          }
        });
      } else {
        // Insert a new record
        const insertSql = 'INSERT INTO stock (produce_pack, produce_totalcones, qty, totalcones, itemGroup, itemName, date) VALUES (?, ?, ?, ?, ?, ?, ?)';
        const insertValues = [produce_pack, produce_totalcones, qty, totalcones, itemGroup, itemName, date];
        db.query(insertSql, insertValues, (insertErr, insertResult) => {
          if (insertErr) {
            console.error('Error inserting new entry:', insertErr);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('New entry inserted successfully');
          }
        });
      }
    }
  });
});

//decrese the withprinting cones after
app.post('/updatewithprinting_production', async (req, res) => {
  const { gsm, itemGroup, itemName, numofcones, status, date } = req.body;

  const sql = 'UPDATE winding_printing_production SET  numofcones = numofcones - ? , date = ? WHERE  gsm = ? AND itemGroup = ? AND itemName = ? AND status = "with printing"';
  const values = [ numofcones, date, gsm, itemGroup, itemName, status,];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});

//16//01/24
app.post('/fetch_raw_material', (req, res) => {
  const { gsm } = req.body;

  const query = `SELECT sNo, totalweight FROM raw_material WHERE prodName = ?`;

  db.query(query, [gsm], (err, results) => {
    if (err) {
      console.log('Error fetching data from MySQL:', err);
      res.status(500).send('Internal Server Error');
    } else {
      if (results.length > 0) {
        const { sNo, totalweight } = results[0];
        res.json({ sNo, totalweight });
      } else {
        res.status(404).send('Data not found');
      }
    }
  });
});


app.post('/fetch_without_printing', (req, res) => {
  const { gsm,status } = req.body;

  const query = `SELECT numofcones FROM winding_printing_production WHERE gsm = ? AND status ="without printing" `;

  db.query(query, [gsm,status], (err, results) => {
    if (err) {
      console.log('Error fetching data from MySQL:', err);
      res.status(500).send('Internal Server Error');
    } else {
      if (results.length > 0) {
        const { numofcones } = results[0];
        res.json({ numofcones });
      } else {
        res.status(404).send('Data not found');
      }
    }
  });
});


app.post('/fetch_with_printing', (req, res) => {
  const { gsm,status } = req.body;

  const query = `SELECT numofcones FROM winding_printing_production WHERE gsm = ? AND status ="with printing" `;

  db.query(query, [gsm,status], (err, results) => {
    if (err) {
      console.log('Error fetching data from MySQL:', err);
      res.status(500).send('Internal Server Error');
    } else {
      if (results.length > 0) {
        const { numofcones } = results[0];
        res.json({ numofcones });
      } else {
        res.status(404).send('Data not found');
      }
    }
  });
});
//17//01
app.get('/winding_entry_get_report_With_Print', (req, res) => {
  const sql = 'SELECT * FROM winding_entry WHERE status = "With Printing"'; // Adding the condition
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/winding_entry_get_report_Without_Print', (req, res) => {
  const sql = 'SELECT * FROM winding_entry WHERE status = "Without Printing"'; // Adding the condition
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//17//01(winding,printing production)
app.get('/winding_printing_production_get_report', (req, res) => {
  const sql = 'SELECT * FROM winding_printing_production'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//22/01/2024
/*
app.post('/updateRawMaterialdailywork', async (req, res) => {
  const { prodName, qty, totalweight, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET  qty = qty - ?, totalweight = totalweight - ?, modifyDate = ? WHERE  prodName = ?';
  const values = [ qty, totalweight, modifyDate, prodName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
*/


app.post('/fetch_Raw_materil_Suggestions', (req, res) => {
  const { pattern } = req.body;
  const query = `
    SELECT prodCode, prodName
    FROM raw_material
    WHERE prodCode LIKE ? OR prodName LIKE ?
    ORDER BY prodCode ASC
  `;

  const patternWithWildcards = `%${pattern}%`;

  db.query(query, [patternWithWildcards, patternWithWildcards], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    const suggestions = results.map((result) => {
      // Combine prodCode and prodName to display in suggestions
      return `${result.prodCode} - ${result.prodName}`;
    });

    res.json({ suggestions });
  });
});



app.post('/Raw_materil_UnitInPO', (req, res) => {
  const { prodCode, prodName } = req.body;
  const query = `SELECT unit FROM raw_material WHERE prodCode = ? AND prodName = ?`;

  db.query(query, [prodCode, prodName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ unit: results[0].unit });
    } else {
      res.json({ unit: '' }); // Return an empty string if no match found
    }
  });
});



app.post('/Raw_materil_Qty', (req, res) => {
  const { prodCode, prodName } = req.body;
  const query = 'SELECT qty FROM raw_material WHERE prodCode = ? AND prodName = ?';

  db.query(query, [prodCode, prodName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }
    if (results.length > 0) {
      res.json({ qty: results[0].qty });
    } else {
      res.json({ qty: '' }); // Return an empty string if no match found
    }
  });
});

app.post('/fetch_with_Qty', (req, res) => {
  const { prodCode } = req.body;

  const query = `SELECT qty FROM raw_material WHERE prodCode = ?`;

  db.query(query, [prodCode], (err, results) => {
    if (err) {
      console.log('Error fetching data from MySQL:', err);
      res.status(500).send('Internal Server Error');
    } else {
      if (results.length > 0) {
        const { qty } = results[0];
        res.json({ qty });
      } else {
        res.status(404).send('Data not found');
      }
    }
  });
});

app.post('/handbill_DC', (req, res) => {
  const { dataToInsertorditem } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO handbill_dc SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertorditem], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error Table inserting data:', err);
      res.status(500).json({ error: 'Error Table inserting data' });
    } else {
      console.log('Table Data inserted successfully');
      res.status(200).json({ message: 'Table Data inserted successfully' });
    }
  });
});


app.get('/gethand_billdcno', (req, res) => {
  const sql = 'SELECT * FROM handbill_dc order by dcNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


//reduse stock
app.post('/sc_to_update_Stock', async (req, res) => {
  const { itemGroup, itemName, qty } = req.body;
  const sql = 'UPDATE stock SET qty=qty-? WHERE itemGroup=? AND itemName=? ';
  const values = [qty, itemGroup, itemName,];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});

app.get('/hand_dc_item_view', (req, res) => {
  const dcNo = req.query.dcNo;
  const sql = `SELECT * FROM handbill_dc WHERE dcNo = ?`;
  db.query(sql, [dcNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

//hand bill dc report
app.get('/gethand_billDC', (req, res) => {
  const sql = 'select * from handbill_dc'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//30/01/24
//get finishing qtyt form DWS
app.get('/get_production_quantity', (req, res) => {
  const createDate = req.query.createDate;
  const machineName = req.query.machineName;
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;

  const query = 'SELECT productionQty FROM daily_work_status WHERE createDate = ? AND machineName = ? AND itemGroup = ? AND itemName = ?';

  db.query(query, [createDate, machineName, itemGroup, itemName], (err, result) => {
    if (err) {
      console.log('Error executing MySQL query:', err);
      res.status(500).send('Internal Server Error');
    } else {
      if (result.length > 0) {
        const productionQuantity = result[0].productionQty; // Fix the field name here
        res.status(200).json({ num_of_production: productionQuantity }); // Fix the field name here
      } else {
        res.status(404).send('Production quantity not found for the specified criteria');
      }
    }
  });
});





app.post('/production_qty_DWS', (req, res) => {
  const { createDate, machineName, itemGroup, itemName } = req.body;
  const query = 'SELECT productionQty FROM daily_work_status WHERE createDate = ? AND machineName = ? itemGroup = ? AND itemGroup = ?';

  db.query(query, [createDate, machineName, itemGroup, itemGroup], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ qty: results[0].qty });
    } else {
      res.json({ qty: '' }); // Return an empty string if no match found
    }
  });
});

/*app.get('/get_serial_no', (req, res) => {
  const sql = 'SELECT sNo FROM raw_material'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});*/


app.post('/Raw_materil_weight', (req, res) => {
  const { id,prodName, sNo } = req.body;
  const query = 'SELECT totalweight FROM raw_material WHERE id = ? AND prodName = ? AND sNo = ?';

  db.query(query, [id, prodName, sNo], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }
    if (results.length > 0) {
      res.json({ totalweight: results[0].totalweight });
    } else {
      res.json({ totalweight: '' }); // Return an empty string if no match found
    }
  });
});



app.post('/fetch_sno_raw', (req, res) => {
  const { prodName } = req.body;
  const query = `SELECT sNo FROM raw_material WHERE prodName = ?`;

  db.query(query, [prodName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ sNo: results[0].sNo });
    } else {
      res.json({ sNo: '' }); // Return an empty string if no match found
    }
  });
});

app.get('/get_serialnum_gsm', (req, res) => {
  const prodName = req.query.prodName;

  const sql = 'SELECT id, sNo FROM raw_material WHERE prodName = ?';

  db.query(sql, [prodName], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});


app.get('/daily_work_status_view', (req, res) => {
  const createDate = req.query.createDate;
  const shiftType = req.query.shiftType;
  const machineType = req.query.machineType;
  const machineName = req.query.machineName;


  const sql = `SELECT * FROM daily_work_status WHERE createDate = ? AND shiftType = ? AND machineType = ? AND machineName = ?`;

  db.query(sql, [createDate, shiftType, machineType, machineName], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});


//raja daily
app.get('/getwindinggsm', (req, res) => {
  const sql = 'select DISTINCT gsm from winding_printing_production'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
//05-04-2024 raja
app.put('/custupdate_update/:id', (req, res) => {
  const { id } = req.params;
  const { custName, custAddress, custMobile, pincode, gstin, rate, modifyDate } = req.body;
  const sql = 'UPDATE customer SET custName = ?, custAddress = ?, custMobile = ?, pincode = ?, gstin = ?, rate = ?, modifyDate = ? WHERE id = ?';
  const values = [custName, custAddress, custMobile, pincode, gstin, rate, modifyDate, id];
  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
//05-04-2024 raja

app.put('/supplier_update/:id', (req, res) => {
  const { id } = req.params;
  const { supName,supAddress,supMobile,pincode,modifyDate } = req.body;
  const sql = 'UPDATE supplier SET supName = ?, supAddress = ?, supMobile = ?, pincode = ? ,modifyDate = ? WHERE id = ?';
  const values = [supName, supAddress, supMobile, pincode ,modifyDate, id];
  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
//567

app.post('/update_admin', async (req, res) => {
  const { company, invoiceNo } = req.body;
  const sql = 'UPDATE sales SET company = ?  WHERE invoiceNo=? ';
  const values = [company, invoiceNo];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});

//cumulative
app.get('/get_cumulative_salary', (req, res) => {
  const fromDate = req.query.fromDate;
  const toDate = req.query.toDate;
  const shiftType = req.query.shiftType;
  const sql = `
    SELECT
      emp_code,
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
      SUM(CASE
            WHEN machineType = "Winding" AND DATE(inDate) = DATE(dws.createDate) THEN extraproduction
            WHEN machineType IN ("Finishing", "Printing") AND DATE(inDate) = DATE(dws.createDate) THEN extraproduction / 2
            ELSE 0
          END) AS calculated_extraproduction
    FROM
      attendance AS a
    LEFT JOIN
      daily_work_status AS dws ON (a.emp_code = dws.op_code OR a.emp_code = dws.ass_code1 OR a.emp_code = dws.ass_code2)
    WHERE
      inDate BETWEEN ? AND ?
      AND a.shiftType = ?
    GROUP BY
      emp_code,
      first_name,
      a.shiftType,
      salary
  `;

  db.query(sql, [fromDate, toDate, shiftType], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});

//raja (12.4)
//item group creation
app.get('/itemGroupscreation', (req, res) => {
  const sql = 'SELECT DISTINCT itemName, IFNULL(hsnCode, "default_hsnCode") AS hsnCode, IFNULL(gst, "default_gst") AS gst, IFNULL(packSize, "default_packSize") AS packSize, IFNULL(unit, "default_unit") AS unit, IFNULL(rate, "default_rate") AS rate FROM item ORDER BY itemName'; // Modify to your table name and specify default values

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.get('/getinvoiceForbyproduct', (req, res) => {
  const sql = 'SELECT * FROM sales order by invoiceNo desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/getkvinvoiceForbyproduct', (req, res) => {
  const sql = 'SELECT * FROM sales order by kvinvoice desc limit 1'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
//save by product sale
app.post('/by_product_sale', (req, res) => {
  const { dataToInsertorditem } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO sales SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertorditem], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error Table inserting data:', err);
      res.status(500).json({ error: 'Error Table inserting data' });
    } else {
      console.log('Table Data inserted successfully');
      res.status(200).json({ message: 'Table Data inserted successfully' });
    }
  });
});


///sales
app.get('/kvsales_item_view', (req, res) => {
  const kvinvoice = req.query.kvinvoice;

  //const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;
  const sql = `SELECT * FROM sales WHERE kvinvoice = ?`;

  db.query(sql, [kvinvoice], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});




//sale edit
app.get('/get_sales_edit_item2', (req, res) => {
  const { kvinvoice, company } = req.query;
  const sql = 'SELECT * FROM sales WHERE kvinvoice = ? AND company = ?'; // Update the SQL query

  db.query(sql, [kvinvoice, company], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/get_sales_edit_item', (req, res) => {
  const { invoiceNo, company } = req.query;
  const sql = 'SELECT * FROM sales WHERE invoiceNo = ? AND company = ?'; // Update the SQL query

  db.query(sql, [invoiceNo, company], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});



app.get('/get_sales_order_item', (req, res) => {
  const { orderNo } = req.query;
  const sql = 'SELECT * FROM pending_sales_order WHERE orderNo = ? '; // Update the SQL query
  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/fetch_sales_datas_invoice/:company', (req, res) => {
  const { company } = req.params;
  const sql = 'SELECT * FROM sales WHERE company = ?';
  db.query(sql, [company], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});

app.get('/fetch_sales_datas_kvinvoice/:company', (req, res) => {
  const { company } = req.params;
  const sql = 'SELECT * FROM sales WHERE company = ?';
  db.query(sql, [company], (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('Data fetched successfully');
      res.status(200).json(result);
    }
  });
});

app.get('/fetch_invoiceNo_duplicate', (req, res) => {
  const sql = 'SELECT * FROM sales';
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



/*app.post('/sales_edit_update', async (req, res) => {
  const { date, invoiceNo, supCode, supName, supMobile, supAddress, gstin, pincode, deliveryType, payType, transportNo, itemGroup, itemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, company } = req.body;

  const sql = 'UPDATE sales SET date = ?, invoiceNo = ?, custCode = ?, custName = ?, custMobile = ?, custAddress = ?, gstin = ?, pincode = ?, deliveryType = ?, payType = ?, transportNo = ?, itemGroup = ?, itemName = ?, qty = ?, totalCone = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ? WHERE invoiceNo = ? AND itemGroup = ? AND itemName = ? AND company = ?'; // Modified query
  const values = [date, invoiceNo, supCode, supName, supMobile, supAddress, gstin, pincode, deliveryType, payType, transportNo, itemGroup, itemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, invoiceNo, itemGroup, itemName, company]; // Modified values array

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating purchase entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Purchase entry updated successfully');
    }
  });
});*/
app.get('/fetch_itemGroup_duplicate', (req, res) => {
  const sql = 'SELECT * FROM stock';
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
app.post('/stock_edit', (req, res) => {
  const { dataToInsertRaw2 } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO stock SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertRaw2], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/add_stock', async (req, res) => {
  const { itemGroup, itemName, qty, totalcones, modifyDate } = req.body;

  const sql = 'UPDATE stock SET qty = qty + ?, totalcones = totalcones + ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ?';
  const values = [qty, totalcones, modifyDate, itemGroup, itemName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
app.post('/minus_stock', async (req, res) => {
  const { itemGroup, itemName, qty, totalcones, modifyDate } = req.body;

  const sql = 'UPDATE stock SET qty = qty - ?, totalcones = totalcones - ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ?';
  const values = [qty, totalcones, modifyDate, itemGroup, itemName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
//sale edit end

//itemName edit
// Update item route
app.put('/itemname_update/:itemName', (req, res) => {
  const { itemName: oldItemName } = req.params; // Rename itemName to oldItemName
  const { gst, hsnCode, updatedDate, newItemName } = req.body;


  const sql = 'UPDATE item SET itemName = ?, gst = ?, hsnCode = ?, updatedDate = ? WHERE itemName = ?';
  const values = [newItemName, gst, hsnCode, updatedDate, oldItemName]; // Use oldItemName here

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});

//shift
app.get('/get_shift', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const sql = `
      SELECT first_name, emp_code
      FROM employee
      WHERE Status = 'Active' AND emp_code NOT IN (
          SELECT emp_code
          FROM shift
          WHERE (fromDate <= ? AND toDate >= ?) OR (fromDate <= ? AND toDate >= ?) OR (fromDate >= ? AND toDate <= ?)
       )`;
    const params = [fromDate, toDate, fromDate, toDate, fromDate, toDate]; // Bind parameters properly
    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});


/*app.get('/get_shift', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const sql = `
       SELECT first_name,emp_code
               FROM
                   employee
               WHERE
                   emp_code NOT IN (
                       SELECT emp_code
                       FROM shift
                WHERE fromDate >= ? AND toDate >= ?
                   );`;
    const params = [fromDate, toDate];
    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});*/

//item group Edit-16-4

/*app.put('/itemgroup_update/:itemGroup', (req, res) => {
  const { itemGroup } = req.params;
  const { itemGroup } = req.body;

  const sql = 'UPDATE item SET itemGroup = ? WHERE itemGroup = ?'; // SQL query to update the itemGroup
  const values = [itemGroup, itemGroup]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});*/

app.delete('/itemgroup_delete/:itemGroup', (req, res) => {
  const { itemGroup } = req.params;

  const sql = 'DELETE FROM item WHERE itemGroup = ?';
  const values = [itemGroup];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});

app.get('/get_itemgroup', (req, res) => {
  const sql = 'SELECT DISTINCT itemGroup FROM item ORDER BY itemGroup'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

/*app.get('/get_fromtodate2', (req, res) => {
    const fromDate = req.query.fromDate;
    const toDate = req.query.toDate;
    const shiftType = req.query.shiftType;

    const sql = `
        SELECT
            vkcones.shift.first_name,
            vkcones.shift.shiftType,
            vkcones.shift.emp_code
        FROM
            vkcones.shift
        WHERE
            vkcones.shift.emp_code NOT IN (
                SELECT emp_code1
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                UNION
                SELECT emp_code2
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
                UNION
                SELECT emp_code3
                FROM vkcones.winding_entry
                WHERE vkcones.winding_entry.fromDate >= ? AND vkcones.winding_entry.toDate <= ?
            )
            AND vkcones.shift.emp_code NOT IN (
                    SELECT DISTINCT emp_code1
                    FROM vkcones.printing_entry
                    WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                    UNION
                    SELECT DISTINCT emp_code2
                    FROM vkcones.printing_entry
                    WHERE vkcones.printing_entry.fromDate >= ? AND vkcones.printing_entry.toDate <= ?
                  )
            AND  vkcones.shift.emp_code NOT IN (
                         SELECT emp_code1
                         FROM vkcones.finishing_entry
                         WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                         UNION
                         SELECT emp_code2
                         FROM vkcones.finishing_entry
                         WHERE vkcones.finishing_entry.fromDate >= ? AND vkcones.finishing_entry.toDate <= ?
                       )
              AND  vkcones.shift.emp_code NOT IN (
                                     SELECT emp_code1
                                     FROM vkcones.other_working_entry
                                     WHERE vkcones.other_working_entry.fromDate >= ? AND vkcones.other_working_entry.toDate <= ?
                    )


            AND vkcones.shift.fromdate <= ?
            AND vkcones.shift.todate >= ?
            AND vkcones.shift.shiftType = ?;
    `;

    const params = [fromDate, toDate,fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate,fromDate, toDate, fromDate, toDate, fromDate, toDate, fromDate, toDate, shiftType];

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error executing SQL query:', err);
            res.status(500).send('Internal Server Error');
            return;
        }
        // Check if the result set is empty
        if (result.length === 0) {
            res.json([]);
        } else {
            res.json(result);
        }
    });
});*/
//Profile
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



//22-4
//itemGroup
app.get('/getItemGroup', (req, res) => {
  const sql = 'SELECT DISTINCT itemGroup FROM item ORDER BY itemGroup'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
//itemName
// get unit
app.post('/fetchunit', (req, res) => {
  const { itemName } = req.body;
  const query = `SELECT packSize FROM item WHERE itemName = ?`;

  db.query(query, [itemName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ packSize: results[0].packSize }); // Return unit instead of itemName
    } else {
      res.json({ packSize: '' }); // Return an empty string if no match found
    }
  });
});

app.post('/fetchgst', (req, res) => {
  const { itemName } = req.body;
  const query = `SELECT gst FROM item WHERE itemName = ?`;

  db.query(query, [itemName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ unit: results[0].unit }); // Return unit instead of itemName
    } else {
      res.json({ unit: '' }); // Return an empty string if no match found
    }
  });
});

//get gst
app.get('/gst_entry', (req, res) => {
  const sql = 'SELECT gst FROM gst_entry'; // Select only id and unit fields
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.post('/fetchrate', (req, res) => {
  const { custCode } = req.body;
  const query = `SELECT rate FROM customer WHERE custCode = ?`;

  db.query(query, [custCode], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ rate: results[0].rate }); // Return unit instead of itemName
    } else {
      res.json({ rate: '' }); // Return an empty string if no match found
    }
  });
});

//fetch hsn
app.post('/fetcHsncode', (req, res) => {
  const { itemName } = req.body;
  const query = `SELECT hsnCode FROM item WHERE itemName = ?`;

  db.query(query, [itemName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ hsnCode: results[0].hsnCode }); // Return unit instead of itemName
    } else {
      res.json({ hsnCode: '' }); // Return an empty string if no match found
    }
  });
});

//fetch gst in itemname
app.post('/fetcGST_itemName', (req, res) => {
  const { itemName } = req.body;
  const query = `SELECT gst FROM item WHERE itemName = ?`;

  db.query(query, [itemName], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }
    if (results.length > 0) {
      res.json({ gst: results[0].gst }); // Return unit instead of itemName
    } else {
      res.json({ gst: '' }); // Return an empty string if no match found
    }
  });
});

// get orderNo
app.get('/getselsorderno', (req, res) => {
    const sql = 'SELECT * FROM sales order by orderNo desc limit 1'; // Modify to your table name

    db.query(sql, (err, results) => {
      if (err) {
        console.error('Error fetching data:', err);
        res.status(500).json({ error: 'Error fetching data' });
      } else {
        res.status(200).json(results);
      }
    });
  });

//  app.get('/noAnddate', (req, res) => {
//    const invoiceNo = req.query.invoiceNo;
//    // Updated SQL query to exclude noNdate starting with 'WO'
//    const sql = `SELECT DISTINCT orderNo FROM sales WHERE invoiceNo = ? AND orderNo NOT LIKE 'WO%'`;
//    db.query(sql, [invoiceNo], (err, result) => {
//      if (err) {
//        throw err;
//      }
//      res.json(result);
//    });
//  });



/*app.post('/sales_edit_update_kv', async (req, res) => {
  const { date, kvinvoice, supCode, supName, supMobile, supAddress, gstin, pincode, deliveryType, payType, transportNo, itemGroup, itemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, company } = req.body;

  const sql = 'UPDATE sales SET date = ?, kvinvoice = ?, custCode = ?, custName = ?, custMobile = ?, custAddress = ?, gstin = ?, pincode = ?, deliveryType = ?, payType = ?, transportNo = ?, itemGroup = ?, itemName = ?, qty = ?, totalCone = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ? WHERE kvinvoice = ? AND itemGroup = ? AND itemName = ? AND company = ?'; // Modified query
  const values = [date, kvinvoice, supCode, supName, supMobile, supAddress, gstin, pincode, deliveryType, payType, transportNo, itemGroup, itemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, kvinvoice, itemGroup, itemName, company]; // Modified values array

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating purchase entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Purchase entry updated successfully');
    }
  });
});*/

  app.post('/sales_edit_update_kv', async (req, res) => {
    const { date, kvinvoice, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, oldItemGroup, newItemGroup,oldItemName, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, id, company } = req.body;

    const updateSql = 'UPDATE sales SET date = ?, kvinvoice = ?, orderNo = ?, custCode = ?, custName = ?, custMobile = ?, custAddress = ?, gstin = ?, pincode = ?, payType = ?, transportNo = ?, itemGroup = ?, itemName = ?, qty = ?, totalCone = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ?, hsnCode= ?, totalTax = ?, totalAmt = ?, totalQty = ?, totalItem = ?, totalCones = ?  WHERE kvinvoice = ? AND itemGroup = ? AND itemName = ? AND id = ? AND company = ?';
    const updateValues = [date, kvinvoice, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, newItemGroup, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal,hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, kvinvoice, oldItemGroup, oldItemName, id, company];

    const insertSql = 'INSERT INTO sales (date, kvinvoice, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, itemGroup, itemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, company) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
    const insertValues = [date, kvinvoice, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, newItemGroup, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, company];

    db.query(updateSql, updateValues, (err, result) => {
      if (err) {
        console.error('Error updating sales entry:', err);
        res.status(500).send('Internal Server Error');
      } else {
        // If no rows were updated, it means the row doesn't exist, so we insert instead
        if (result.affectedRows === 0) {
          db.query(insertSql, insertValues, (err, result) => {
            if (err) {
              console.error('Error inserting sales entry:', err);
              res.status(500).send('Internal Server Error');
            } else {
              res.send('Sales entry inserted successfully');
            }
          });
        } else {
          res.send('Sales entry updated successfully');
        }
      }
    });
  });

  //sale edit for new row
  app.post('/sales_edit_update', async (req, res) => {
    const { date, invoiceNo, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, oldItemGroup, newItemGroup,oldItemName, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, id, company } = req.body;

    const updateSql = 'UPDATE sales SET date = ?, invoiceNo = ?, orderNo = ?, custCode = ?, custName = ?, custMobile = ?, custAddress = ?, gstin = ?, pincode = ?, payType = ?, transportNo = ?, itemGroup = ?, itemName = ?, qty = ?, totalCone = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ?, hsnCode= ?, totalTax = ?, totalAmt = ?, totalQty = ?, totalItem = ?, totalCones = ?  WHERE invoiceNo = ? AND itemGroup = ? AND itemName = ? AND ID = ? AND company = ?';
    const updateValues = [date, invoiceNo, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, newItemGroup, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal,hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, invoiceNo, oldItemGroup, oldItemName, id, company];

    const insertSql = 'INSERT INTO sales (date, invoiceNo, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode,, payType, transportNo, itemGroup, itemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, company) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
    const insertValues = [date, invoiceNo, orderNo, custCode, custName, custMobile, custAddress, gstin, pincode, payType, transportNo, newItemGroup, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, hsnCode, totalTax, totalAmt, totalQty, totalItem, totalCones, company];

    db.query(updateSql, updateValues, (err, result) => {
      if (err) {
        console.error('Error updating sales entry:', err);
        res.status(500).send('Internal Server Error');
      } else {
        // If no rows were updated, it means the row doesn't exist, so we insert instead
        if (result.affectedRows === 0) {
          db.query(insertSql, insertValues, (err, result) => {
            if (err) {
              console.error('Error inserting sales entry:', err);
              res.status(500).send('Internal Server Error');
            } else {
              res.send('Sales entry inserted successfully');
            }
          });
        } else {
          res.send('Sales entry updated successfully');
        }
      }
    });
  });

 /* app.post('/sales_edit_update', async (req, res) => {
    const { date, invoiceNo, supCode, supName, supMobile, supAddress, gstin, pincode, deliveryType, payType, transportNo, oldItemGroup, newItemGroup,oldItemName, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, company } = req.body;

    const sql = 'UPDATE sales SET date = ?, invoiceNo = ?, custCode = ?, custName = ?, custMobile = ?, custAddress = ?, gstin = ?, pincode = ?, deliveryType = ?, payType = ?, transportNo = ?, itemGroup = ?, itemName = ?, qty = ?, totalCone = ?, rate = ?, amt = ?, gst = ?, amtGST = ?, total = ?, grandTotal = ? WHERE invoiceNo = ? AND itemGroup = ? AND itemName = ? AND company = ?';
    const values = [date, invoiceNo, supCode, supName, supMobile, supAddress, gstin, pincode, deliveryType, payType, transportNo, newItemGroup, newItemName, qty, totalCone, rate, amt, gst, amtGST, total, grandTotal, invoiceNo, oldItemGroup, oldItemName, company];

    db.query(sql, values, (err, result) => {
      if (err) {
        console.error('Error updating sales entry:', err);
        res.status(500).send('Internal Server Error');
      } else {
        res.send('Sales entry updated successfully');
      }
    });
  });*/


//delete sale item
app.delete('/sales_item_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM sales WHERE id = ?';
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


app.get('/kvnoAnddate', (req, res) => {
  const kvinvoice = req.query.kvinvoice;
  const sql = `SELECT DISTINCT noNdate FROM sales where kvinvoice =?;
`;
  db.query(sql, [kvinvoice], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.get('/noAnddate', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = `SELECT DISTINCT noNdate FROM sales where invoiceNo =?;
`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

/*app.get('/noAnddate', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  // Updated SQL query to exclude noNdate starting with 'WO'
  const sql = `SELECT DISTINCT noNdate FROM sales WHERE invoiceNo = ? AND noNdate NOT LIKE 'WO%'`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});*/


app.post('/fetchEmployees', (req, res) => {
  const { pattern, fromDate, toDate } = req.body;
  const query = `
    SELECT emp_code, first_name
    FROM employee
    WHERE (emp_code LIKE ? OR first_name LIKE ?)AND Status = 'Active'
    AND NOT EXISTS (
      SELECT 1
      FROM shift
      WHERE shift.emp_code = employee.emp_code
      AND fromDate <= ? AND toDate >= ?
    )
  `;
  const patternWithWildcards = `%${pattern}%`;

  db.query(query, [patternWithWildcards, patternWithWildcards, toDate, fromDate], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    const suggestions = results.map((result) => {
      // Combine emp_code and first_name to display in suggestions
      return `${result.emp_code} - ${result.first_name}`;
    });

    res.json({ suggestions });
  });
});



/*
app.post('/fetchEmployees', (req, res) => {
  const { pattern } = req.body;
  const query = `
    SELECT emp_code, first_name
    FROM employee
    WHERE emp_code LIKE ? OR first_name LIKE ?
  `;
  const patternWithWildcards = `%${pattern}%`;

  db.query(query, [patternWithWildcards, patternWithWildcards], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    const suggestions = results.map((result) => {
      // Combine prodCode and prodName to display in suggestions
      return `${result.emp_code} - ${result.first_name}`;
    });

    res.json({ suggestions });
  });
});*/

app.post('/Shift_entry', (req, res) => {
  const { dataToInsertSupItem1 } = req.body;
  const sql = 'INSERT INTO shift SET ?';
  console.log('SQL Query:', sql);
  db.query(sql, [dataToInsertSupItem1], (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

app.get('/daily_work_status_winding', (req, res) => {
  const selectedDate = req.query.selectedDate;
  const shiftType = req.query.shiftType;
  //const machName = req.query.machName;

  const sql = `SELECT * FROM shift WHERE
                 ? BETWEEN fromDate AND toDate AND
                 fromDate <= ? AND toDate >= ? AND
                 (alterEmp = 'Yes' OR (alterEmp IS NULL AND NOT EXISTS (
                     SELECT 1 FROM shift sub
                     WHERE ? BETWEEN sub.fromDate AND sub.toDate
                       AND sub.fromDate <= ? AND sub.toDate >= ?
                       AND sub.shiftType = ?
                       AND sub.alterEmp = 'Yes'
                 ))) AND
                 shiftType = ?`;
  db.query(
    sql,
    [selectedDate, selectedDate, selectedDate, selectedDate, selectedDate, selectedDate, shiftType, shiftType],
    (err, result) => {
      if (err) {
        console.error('Error executing SQL query:', err);
        res.status(500).json({ error: 'Internal Server Error' });
      } else {
        console.log('Result:', result);  // Debugging purpose
        res.json(result);
      }
    }
  );
});

app.get('/daily_work_status_printing', (req, res) => {
  const selectedDate = req.query.selectedDate;
  const shiftType = req.query.shiftType;
  const machName = req.query.machName;

  const sql = `SELECT * FROM printing_entry WHERE
               ? BETWEEN fromDate AND toDate AND
               fromDate <= ? AND toDate >= ? AND
               (AltEmp = 'Yes' OR (AltEmp IS NULL AND NOT EXISTS (
                   SELECT 1 FROM printing_entry sub
                   WHERE ? BETWEEN sub.fromDate AND sub.toDate
                     AND sub.fromDate <= ? AND sub.toDate >= ?
                     AND sub.shiftType = ? AND sub.machName = ?
                     AND sub.AltEmp = 'Yes'
               ))) AND
               shiftType = ? AND machName = ?`;

  db.query(
    sql,
    [selectedDate, selectedDate, selectedDate, selectedDate, selectedDate, selectedDate, shiftType, machName, shiftType, machName],
    (err, result) => {
      if (err) {
        console.error('Error executing SQL query:', err);
        res.status(500).json({ error: 'Internal Server Error' });
      } else {
        console.log('Result:', result);  // Debugging purpose
        res.json(result);
      }
    }
  );
});

app.get('/daily_work_status_finishing', (req, res) => {
  const selectedDate = req.query.selectedDate;
  const shiftType = req.query.shiftType;
  const machName = req.query.machName;

  const sql = `SELECT * FROM finishing_entry WHERE
               ? BETWEEN fromDate AND toDate AND
               fromDate <= ? AND toDate >= ? AND
               (AltEmp = 'Yes' OR (AltEmp IS NULL AND NOT EXISTS (
                   SELECT 1 FROM finishing_entry sub
                   WHERE ? BETWEEN sub.fromDate AND sub.toDate
                     AND sub.fromDate <= ? AND sub.toDate >= ?
                     AND sub.shiftType = ? AND sub.machName = ?
                     AND sub.AltEmp = 'Yes'
               ))) AND
               shiftType = ? AND machName = ?`;

  db.query(
    sql,
    [selectedDate, selectedDate, selectedDate, selectedDate, selectedDate, selectedDate, shiftType, machName, shiftType, machName],
    (err, result) => {
      if (err) {
        console.error('Error executing SQL query:', err);
        res.status(500).json({ error: 'Internal Server Error' });
      } else {
        console.log('Result:', result);  // Debugging purpose
        res.json(result);
      }
    }
  );
});
//get_sales_product_items


app.get('/get_sales_order_item_for_saleorder', (req, res) => {
  try {
    const { orderNo } = req.query;

    if (!orderNo) {
      return res.status(400).json({ error: 'Bad Request', message: 'Order number not provided.' });
    }

    const query = `
      SELECT
        custName,
        custCode,
        orderNo,
        deliveryType,
        itemGroup,
        itemName,
        CONCAT(DATE_FORMAT(date, '%d-%m-'), SUBSTRING(YEAR(date), 3)) as date,
        qty
      FROM
        purchase_order
      WHERE
        orderNo = ?
    `;

    db.query(query, [orderNo], (error, results) => {
      if (error) {
        console.error('Error executing query:', error);
        res.status(500).json({ error: 'Internal Server Error', message: error.message });
      } else {
        res.json(results);
      }
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});


app.get('/get_sales_orderNo', (req, res) => {
  const sql = 'SELECT DISTINCT orderNo FROM pending_sales_order ORDER BY orderNo'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

//save pending sale order 30-04
app.post('/pendingsaleorder_entry', (req, res) => {
  const { dataToInsert } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO pending_sales_order SET ?'; // Modify to your table name

  db.query(sql, dataToInsert, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});

//update sale order
app.post('/sales_to_update_Sale_Order', async (req, res) => {
  const { itemGroup, itemName, qty, orderNo } = req.body;
  const updateSql = 'UPDATE pending_sales_order SET qty = qty - ? WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
  const deleteSql = 'DELETE FROM pending_sales_order WHERE itemGroup = ? AND itemName = ? AND qty <= 0 AND orderNo = ?';
  const values = [qty, itemGroup, itemName, orderNo];

  db.query(updateSql, values, (err, result) => {
    if (err) {
      console.error('Error updating pending_sales_order:', err);
      res.status(500).send('Internal Server Error');
    } else {
      // After update, delete rows where qty <= 0
      db.query(deleteSql, [itemGroup, itemName, orderNo], (err, result) => {
        if (err) {
          console.error('Error deleting pending_sales_order:', err);
          res.status(500).send('Internal Server Error');
        } else {
          res.send('Sales order updated successfully');
        }
      });
    }
  });
});

app.get('/get_sales_orderitem', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

/*app.post('/sales_to_update_Sale_Order', async (req, res) => {
  const { itemGroup, itemName, qty, orderNo } = req.body;
  const sql = 'UPDATE pending_sales_order SET qty=qty-?  WHERE itemGroup=? AND itemName=? AND orderNo = ?';
  const values = [qty, itemGroup, itemName, orderNo];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});*/

app.get('/sales_pending_item_view', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT * FROM pending_sales_order WHERE orderNo = ?`;

   db.query(sql, [orderNo], (err, result) => {
     if (err) {
       throw err;
     }
     if (result.length > 0) {
       // Order exists in the pending_sales_order table
       return true;
     } else {
       // Order doesn't exist in the pending_sales_order table
       return false;
     }
   });

});

//update pending
/*app.post('/add_pending', async (req, res) => {
  const { custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate } = req.body;

  // First, check if the orderNo exists in the purchase_order table
  const checkOrderNoQuery = 'SELECT COUNT(*) AS count FROM purchase_order WHERE orderNo = ?';
  const checkOrderNoValues = [orderNo];

  db.query(checkOrderNoQuery, checkOrderNoValues, (err, result) => {
    if (err) {
      console.error('Error checking if orderNo exists in purchase_order:', err);
      res.status(500).send('Internal Server Error');
    } else {
      const count = result[0].count;

      if (count === 0) {
        // If the orderNo doesn't exist in purchase_order, send a response indicating the error
        res.status(400).send('OrderNo does not exist in purchase_order');
      } else {
        // If the orderNo exists in purchase_order, proceed to check if the combination of orderNo, itemName, and itemGroup exists in pending_sales_order
        const checkIfExistsQuery = 'SELECT COUNT(*) AS count FROM pending_sales_order WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
        const checkIfExistsValues = [itemGroup, itemName, orderNo];

        db.query(checkIfExistsQuery, checkIfExistsValues, (err, result) => {
          if (err) {
            console.error('Error checking if entry exists:', err);
            res.status(500).send('Internal Server Error');
          } else {
            const count = result[0].count;

            if (count === 0) {
              // If the entry doesn't exist, insert a new row
              const insertQuery = 'INSERT INTO pending_sales_order (custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate) VALUES (?, ?, ?, ?, ?, ?, ?)';
              const insertValues = [custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate];

              db.query(insertQuery, insertValues, (err, result) => {
                if (err) {
                  console.error('Error inserting new entry:', err);
                  res.status(500).send('Internal Server Error');
                } else {
                  res.send('New entry inserted successfully');
                }
              });
            } else {
              // If the entry exists, update the existing row
              const updateQuery = 'UPDATE pending_sales_order SET qty = qty + ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
              const updateValues = [qty, modifyDate, itemGroup, itemName, orderNo];

              db.query(updateQuery, updateValues, (err, result) => {
                if (err) {
                  console.error('Error updating existing entry:', err);
                  res.status(500).send('Internal Server Error');
                } else {
                  res.send('Existing entry updated successfully');
                }
              });
            }
          }
        });
      }
    }
  });
});*/
app.post('/add_pending', async (req, res) => {
  const { custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate } = req.body;

  // Check if the orderNo exists in the purchase_order table
  const checkOrderNoQuery = 'SELECT COUNT(*) AS count FROM purchase_order WHERE orderNo = ?';
  const checkOrderNoValues = [orderNo];

  db.query(checkOrderNoQuery, checkOrderNoValues, (err, result) => {
    if (err) {
      console.error('Error checking if orderNo exists in purchase_order:', err);
      res.status(500).send('Internal Server Error');
      return;
    }

    const count = result[0].count;

    if (count === 0) {
      // If the orderNo doesn't exist in purchase_order, send a response indicating the error
      res.status(400).send('OrderNo does not exist in purchase_order');
      return;
    }

    // If the orderNo exists in purchase_order, proceed to insert or update in pending_sales_order
    const checkIfExistsQuery = 'SELECT COUNT(*) AS count FROM pending_sales_order WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
    const checkIfExistsValues = [itemGroup, itemName, orderNo];

    db.query(checkIfExistsQuery, checkIfExistsValues, (err, result) => {
      if (err) {
        console.error('Error checking if entry exists:', err);
        res.status(500).send('Internal Server Error');
        return;
      }

      const count = result[0].count;

      if (count === 0) {
        // If the entry doesn't exist, insert a new row
        const insertQuery = 'INSERT INTO pending_sales_order (custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate) VALUES (?, ?, ?, ?, ?, ?, ?)';
        const insertValues = [custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate];

        db.query(insertQuery, insertValues, (err, result) => {
          if (err) {
            console.error('Error inserting new entry:', err);
            res.status(500).send('Internal Server Error');
            return;
          }
          res.send('New entry inserted successfully');
        });
      } else {
        // If the entry exists, update the existing row
        const updateQuery = 'UPDATE pending_sales_order SET qty = qty + ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
        const updateValues = [qty, modifyDate, itemGroup, itemName, orderNo];

        db.query(updateQuery, updateValues, (err, result) => {
          if (err) {
            console.error('Error updating existing entry:', err);
            res.status(500).send('Internal Server Error');
            return;
          }
          res.send('Existing entry updated successfully');
        });
      }
    });
  });
});

/*app.post('/add_pending', async (req, res) => {
  const { custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate } = req.body;

  // First, check if the combination of orderNo, itemName, and itemGroup exists
  const checkIfExistsQuery = 'SELECT COUNT(*) AS count FROM pending_sales_order WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
  const checkIfExistsValues = [itemGroup, itemName, orderNo];

  db.query(checkIfExistsQuery, checkIfExistsValues, (err, result) => {
    if (err) {
      console.error('Error checking if entry exists:', err);
      res.status(500).send('Internal Server Error');
    } else {
      const count = result[0].count;

      if (count === 0) {
        // If the entry doesn't exist, insert a new row
        const insertQuery = 'INSERT INTO pending_sales_order (custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate) VALUES (?, ?, ?, ?, ?, ?, ?)';
        const insertValues = [custName, custCode, itemGroup, itemName, orderNo, qty, modifyDate];

        db.query(insertQuery, insertValues, (err, result) => {
          if (err) {
            console.error('Error inserting new entry:', err);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('New entry inserted successfully');
          }
        });
      } else {
        // If the entry exists, update the existing row
        const updateQuery = 'UPDATE pending_sales_order SET qty = qty + ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
        const updateValues = [qty, modifyDate, itemGroup, itemName, orderNo];

        db.query(updateQuery, updateValues, (err, result) => {
          if (err) {
            console.error('Error updating existing entry:', err);
            res.status(500).send('Internal Server Error');
          } else {
            res.send('Existing entry updated successfully');
          }
        });
      }
    }
  });
});*/


app.post('/minus_pending', async (req, res) => {
  const { itemGroup, itemName, qty, orderNo, modifyDate } = req.body;

  const sql = 'UPDATE pending_sales_order SET qty = qty - ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
  const values = [qty, orderNo, modifyDate, itemGroup, itemName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
/*app.post('/minus_pending', async (req, res) => {
  try {
    const { itemGroup, itemName, orderNo, qty, modifyDate } = req.body;
    const sql = 'UPDATE pending_sales_order SET qty = qty - ?, modifyDate = ? WHERE itemGroup = ? AND itemName = ? AND orderNo = ?';
    const values = [qty, modifyDate, itemGroup, itemName, orderNo];

    // Assuming db.query returns a promise
    await db.query(sql, values);

    res.send('raw_material updated successfully');
  } catch (error) {
    console.error('Error updating raw_material entry:', error);
    res.status(500).send('Internal Server Error');
  }
});*/


app.delete('/vksales_delete/:invoiceNo', (req, res) => {
  const { invoiceNo } = req.params;
  console.log('Received DELETE request for invoiceNo:', invoiceNo);

  const sql = 'DELETE FROM sales WHERE invoiceNo = ?';
  const values = [invoiceNo];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      console.log('Data deleted successfully');
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});

app.delete('/kvsales_delete/:kvinvoice', (req, res) => {
  const { kvinvoice } = req.params;
  console.log('Received DELETE request for kvinvoice:', kvinvoice);

  const sql = 'DELETE FROM sales WHERE kvinvoice = ?';
  const values = [kvinvoice];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error deleting data:', err);
      res.status(500).json({ error: 'Error deleting data' });
    } else {
      console.log('Data deleted successfully');
      res.status(200).json({ message: 'Data deleted successfully' });
    }
  });
});

app.put('/unit_update_item/:unit', (req, res) => {
  const { unit } = req.params;
  const { packSize } = req.body;

  const sql = 'UPDATE item SET packSize = ? WHERE unit = ?'; // SQL query to update the itemGroup
  const values = [packSize, unit]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});

//chck daily work status
app.get('/daily_work_entry_duplicatecheck', (req, res) => {
  const sql = 'SELECT * FROM daily_work_status';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

/*app.get('/get_fromtodate222', (req, res) => {
  const { fromDate, toDate, shiftType } = req.query;

  const sql = `
    SELECT
        vkcones.shift.first_name,
        vkcones.shift.shiftType,
        CASE
            WHEN vkcones.shift.alterEmp IS NOT NULL AND vkcones.shift.alterEmpID IS NOT NULL THEN vkcones.shift.alterEmp
            ELSE vkcones.shift.emp_code
        END AS emp_code,
        CASE
            WHEN vkcones.shift.alterEmp IS NOT NULL AND vkcones.shift.alterEmpID IS NOT NULL THEN 'Alter Employee'
            ELSE 'Regular Employee'
        END AS employee_type
    FROM
        vkcones.shift
    WHERE
        vkcones.shift.fromDate <= ? AND
        vkcones.shift.toDate >= ? AND
        vkcones.shift.shiftType = ?
  `;

  const params = [fromDate, toDate, shiftType];

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).json({ error: 'Internal Server Error' });
      return;
    }

    res.json(result);
  });
});*/


app.get('/get_fromtodate222', (req, res) => {
  const { fromDate, toDate, shiftType } = req.query;

  const sql = `
    SELECT
        vkcones.shift.first_name,
        vkcones.shift.shiftType,
        vkcones.shift.emp_code,
        vkcones.shift.alterEmp,
        vkcones.shift.alterEmpID
    FROM
        vkcones.shift
    WHERE
        vkcones.shift.fromDate <= ? AND
        vkcones.shift.toDate >= ? AND
        vkcones.shift.shiftType = ?
  `;

  const params = [fromDate, toDate, shiftType];

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).json({ error: 'Internal Server Error' });
      return;
    }

    res.json(result);
  });
});

/*app.get('/get_fromtodate222', (req, res) => {
  const { fromDate, toDate, shiftType } = req.query;

  const sql = `
    SELECT
        vkcones.shift.first_name,
        vkcones.shift.shiftType,
        vkcones.shift.emp_code
    FROM
        vkcones.shift
    WHERE
        vkcones.shift.fromDate <= ? AND
        vkcones.shift.toDate >= ? AND
        vkcones.shift.shiftType = ?
  `;

  const params = [fromDate, toDate, shiftType];

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).json({ error: 'Internal Server Error' });
      return;
    }

    res.json(result);
  });
});*/

app.get('/get_VKsales_entry', (req, res) => {
  const sql = "SELECT * FROM sales WHERE company = 'VKcones' ORDER BY invoiceNo DESC";
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


app.get('/get_KVsales_entry', (req, res) => {
  const sql = "SELECT * FROM sales WHERE company = 'KVcones' ORDER BY kvinvoice DESC";
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

app.post('/fetchunitsettings', (req, res) => {
  const { unit } = req.body;
  const query = `SELECT packSize FROM unit_entry WHERE unit = ?`;

  db.query(query, [unit], (error, results) => {
    if (error) {
      console.error('MySQL Error: ' + error);
      res.status(500).json({ message: 'Internal Server Error' });
      return;
    }

    if (results.length > 0) {
      res.json({ packSize: results[0].packSize }); // Return unit instead of itemName
    } else {
      res.json({ packSize: '' }); // Return an empty string if no match found
    }
  });
});

//update status in sales
app.post('/update_sales_status', (req, res) => {
  const invoiceNo = req.body.invoiceNo;
  const sql = `UPDATE sales SET status = 'Paid' WHERE invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      console.error('Error updating sales status:', err);
      res.status(500).json({ error: 'Error updating sales status' });
    } else {
      console.log('Sales status updated successfully');
      res.status(200).json({ message: 'Sales status updated successfully' });
    }
  });
});

app.post('/update_kvsales_status', (req, res) => {
  const kvinvoice = req.body.kvinvoice;
  const sql = `UPDATE sales SET status = 'Paid' WHERE kvinvoice = ?`;
  db.query(sql, [kvinvoice], (err, result) => {
    if (err) {
      console.error('Error updating sales status:', err);
      res.status(500).json({ error: 'Error updating sales status' });
    } else {
      console.log('Sales status updated successfully');
      res.status(200).json({ message: 'Sales status updated successfully' });
    }
  });
});

app.post('/update_purchase_status', (req, res) => {
  const invoiceNo = req.body.invoiceNo;
  const sql = `UPDATE purchase SET Status = 'Paid' WHERE invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      console.error('Error updating sales status:', err);
      res.status(500).json({ error: 'Error updating sales status' });
    } else {
      console.log('Sales status updated successfully');
      res.status(200).json({ message: 'Sales status updated successfully' });
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



// shift
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
app.put('/shift_update_tvs:id', (req, res) => {
  const { id } = req.params;
  const { shiftType } = req.body;
  const { startTime } = req.body;
  const { endTime } = req.body;

  const sql = 'UPDATE shift SET shiftType = ? , startTime = ? , endTime = ?  WHERE id = ?'; // SQL query to update the itemGroup
  const values = [shiftType, startTime, endTime, id]; // Values to replace the placeholders (?)

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});
app.put('/time_update_tvs/:id', (req, res) => {
  const { id } = req.params;
  const { shiftType, checkin_start, checkin_end, checkout_start, checkout_end,
          lunchout_start, lunchout_end, lunchin_start, lunchin_end } = req.body;

  const sql = `
    UPDATE time
    SET
      shiftType = ?,
      checkin_start = ?,
      checkin_end = ?,
      checkout_start = ?,
      checkout_end = ?,
      lunchout_start = ?,
      lunchout_end = ?,
      lunchin_start = ?,
      lunchin_end = ?
    WHERE id = ?
  `;

  const values = [
    shiftType,
    checkin_start, checkin_end,
    checkout_start, checkout_end,
    lunchout_start, lunchout_end,
    lunchin_start, lunchin_end,
    id
  ];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});


/// 17-06-2024 gowtham done for present and absent home page work
app.get('/attendance-summaryold', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in YYYY-MM-DD format
  const currentTime = new Date().toTimeString().split(' ')[0]; // Get current time in HH:MM:SS format

  const queryTotalEmployees = `SELECT COUNT(*) AS totalEmployees FROM employee`;
  const queryPresent = `SELECT COUNT(*) AS present FROM attendance WHERE inDate = ? AND check_in IS NOT NULL`;
  const queryAbsent = `SELECT COUNT(*) AS absent FROM attendance WHERE inDate = ? AND (check_in IS NULL OR check_in >= '06:00:00')`;

  db.query(queryTotalEmployees, (err, totalEmployeesResult) => {
    if (err) {
      return res.status(500).json({ error: err });
    }
    db.query(queryPresent, [currentDate], (err, presentResult) => {
      if (err) {
        return res.status(500).json({ error: err });
      }
      db.query(queryAbsent, [currentDate], (err, absentResult) => {
        if (err) {
          return res.status(500).json({ error: err });
        }
        res.json({
          totalEmployees: totalEmployeesResult[0].totalEmployees,
          present: presentResult[0].present,
          absent: absentResult[0].absent
        });
      });
    });
  });
});

app.get('/attendance-summary', (req, res) => {
  const currentDate = new Date().toISOString().split('T')[0]; // Get current date in YYYY-MM-DD format

  const queryTotalEmployees = `SELECT COUNT(*) AS totalEmployees FROM employee`;
  const queryPresent = `SELECT COUNT(DISTINCT emp_code) AS present FROM attendance WHERE inDate = ?`;
  const queryAbsent = `SELECT COUNT(*) AS absent FROM employee WHERE emp_code NOT IN (SELECT DISTINCT emp_code FROM attendance WHERE inDate = ?)`;

  db.query(queryTotalEmployees, (err, totalEmployeesResult) => {
    if (err) {
      return res.status(500).json({ error: err });
    }
    db.query(queryPresent, [currentDate], (err, presentResult) => {
      if (err) {
        return res.status(500).json({ error: err });
      }
      db.query(queryAbsent, [currentDate], (err, absentResult) => {
        if (err) {
          return res.status(500).json({ error: err });
        }
        res.json({
          totalEmployees: totalEmployeesResult[0].totalEmployees,
          present: presentResult[0].present,
          absent: absentResult[0].absent
        });
      });
    });
  });
});

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


app.delete('/shift_tvs_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM shift WHERE id = ?';
  db.query(sql, [id], (err, result) => {
    if (err) {
      console.error('Error executing query:', err);
      res.status(500).send('Error deleting shift from database');
      return;
    }

    if (result.affectedRows === 0) {
      res.status(404).send('Shift not found');
    } else {
      res.status(200).send('Shift deleted successfully');
    }
  });
});


app.get('/get_attendance_overallold', (req, res) => {
  const sql = 'SELECT * from attendance'; // Assuming id is the primary key of the attendance table
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



app.get('/get_attendance_overall', (req, res) => {
  const { fromDate, toDate, emp_code, first_name } = req.query;

  let sqlAttendanceDates = 'SELECT DISTINCT inDate FROM attendance WHERE 1=1';
  let sqlAttendance = 'SELECT * FROM attendance WHERE 1=1';
  let sqlEmployees = 'SELECT * FROM employee WHERE 1=1';
  const params = [];

  if (fromDate) {
    sqlAttendanceDates += ' AND inDate >= ?';
    sqlAttendance += ' AND inDate >= ?';
    params.push(fromDate);
  }
  if (toDate) {
    sqlAttendanceDates += ' AND inDate <= ?';
    sqlAttendance += ' AND inDate <= ?';
    params.push(toDate);
  }
  if (emp_code) {
    sqlEmployees += ' AND emp_code = ?';
    params.push(emp_code);
  }
  if (first_name) {
    sqlEmployees += ' AND first_name LIKE ?';
    params.push(`%${first_name}%`);
  }

  db.query(sqlEmployees, params, (errEmployees, resultEmployees) => {
    if (errEmployees) {
      console.error('Error fetching employee data:', errEmployees);
      res.status(500).json({ error: 'Error fetching employee data' });
    } else {
      db.query(sqlAttendanceDates, params, (errDates, resultDates) => {
        if (errDates) {
          console.error('Error fetching attendance dates:', errDates);
          res.status(500).json({ error: 'Error fetching attendance dates' });
        } else {
          const uniqueDates = resultDates.map(row => row.inDate);

          db.query(sqlAttendance, params, (errAttendance, resultAttendance) => {
            if (errAttendance) {
              console.error('Error fetching attendance data:', errAttendance);
              res.status(500).json({ error: 'Error fetching attendance data' });
            } else {
              // Create a map with emp_code and inDate as the key
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
                  combinedData.push({
                    ...emp,
                    inDate: date,
                    check_in: attendance ? attendance.check_in : '',
                    check_out: attendance ? attendance.check_out : '',
                    total_hrs: attendance ? attendance.total_hrs : '',
                    remark: attendance ? 'Present' : 'Absent'
                  });
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



app.post('/shift_insert_tvs', (req, res) => {
  const { shiftType, startTime, endTime } = req.body;

  // Insert into MySQL
  const sql = 'INSERT INTO shift (shiftType, startTime, endTime) VALUES (?, ?, ?)';
  db.query(sql, [shiftType, startTime, endTime], (err, result) => {
    if (err) {
      console.error('Error executing query:', err);
      res.status(500).send('Error inserting shift into database');
      return;
    }

    console.log('Shift added:', result);

    // Respond with the inserted data (optional)
    res.status(200).json({
      id: result.insertId,
      shiftType,
      startTime,
      endTime
    });
  });
});





// Starting the server
app.listen(app.get('port'), () => {
  console.log('Server on port', app.get('port'));
});
