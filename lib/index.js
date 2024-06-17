/*

const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');
const app = express();

// Settings
app.set('port', process.env.PORT || 3309);

// Middlewares
app.use(express.json());
app.use(cors());

// MySQL connection
const db = mysql.createConnection({
   host: 'localhost',
   user: 'root',
   password: 'root123',
   database: 'vinayaga_cones',
});

// Connect to MySQL
db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
  } else {
    console.log('Connected to MySQL');
  }
});


//raja
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

*/
/*app.get('/getSales', (req, res) => {
  const invoiceNo = req.query.invoiceNo;
  const sql = `SELECT s.invoiceNo, s.itemGroup, s.itemName,s.orderNo, s.custCode, s.custName, s.amtGST, s.total,s.grandTotal, s.qty, s.rate,c.custMobile, c.custAddress FROM sales s INNER JOIN customer c ON s.custCode = c.custCode WHERE s.invoiceNo = ?`;
  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});*//*


*/
/*app.get('/getSales', (req, res) => {
  const sql = `SELECT s.invoiceNo, s.itemGroup, s.itemName,s.orderNo, s.custCode, s.custName, s.amtGST, s.total,s.grandTotal, s.qty, s.rate,c.custMobile, c.custAddress
  FROM sales s
  INNER JOIN customer c ON s.custCode = c.custCode
  WHERE s.invoiceNo = ?`; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});*//*

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
//stock to sales
app.put('/stock/update/:itemGroup/:itemName/:size/:color', (req, res) => {
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const size = req.params.size;
  const color = req.params.color;
  const { qtyIncrement } = req.body;

  console.log('Values before update:', req.body);
  const sql = 'UPDATE stock SET  qty=qty+? WHERE itemGroup=? AND itemName=? AND size=? AND color =?';
  const values = [qtyIncrement, itemGroup, itemName, size, color];

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
  const { itemGroup, itemName, size, color, qty } = req.body;
  const sql = 'UPDATE stock SET qty=qty-? WHERE itemGroup=? AND itemName=? AND size=? AND color=?';
  const values = [qty, itemGroup, itemName, size, color];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});
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
app.get('/getItemGroup', (req, res) => {
  const sql = 'select itemGroup from item'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/get_unit_by_iG_iN', (req, res) => {
  const itemGroup = req.query.itemGroup;
  const itemName = req.query.itemName;
  const size = req.query.size;
  const color = req.query.color;

  const sql = 'SELECT unit FROM item WHERE itemGroup = ? AND itemName = ? AND size = ? AND color = ?';

  // Logging parameters for debugging
  console.log('itemGroup:', itemGroup);
  console.log('itemName:', itemName);
  console.log('size:', size);
  console.log('color:', color);

  db.query(sql, [itemGroup, itemName, size, color], (err, result) => {
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

app.get('/getitemname', (req, res) => {
  const sql = 'SELECT * from item'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
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

//purchase order check
app.get('/ordernumcheck', (req, res) => {
  const sql = 'SELECT * FROM purchase_order'; // Modify to your table name
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
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

//customer
//customer update
app.put('/custupdate_update/:id', (req, res) => {
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
});

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

app.get('/getBalance', (req, res) => {
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

//end raja



//elango

//shift
*/
/*app.post('/shift_data', (req, res) => {
  const { dataToInsertShift } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO shift SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertShift], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});*//*


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
*/
/*app.post('/po_data', (req, res) => {
  const { dataToInsertSupplier1 } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO po SET ?'; // Modify to your table name

  console.log('SQL Query:', sql); // Print the SQL query to the console

  db.query(sql, [dataToInsertSupplier1], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/po_item', (req, res) => {
  const { dataToInsertSupItem1 } = req.body;
  const sql = 'INSERT INTO po_item SET ?';
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
});*//*

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
app.post('/updateRawMaterial', async (req, res) => {
  const { prodCode, prodName, qty, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET qty=qty-?, modifyDate=? WHERE prodCode=? AND prodName=?';
  const values = [qty, modifyDate, prodCode, prodName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});


//Raw material
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
//purchase entry
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
app.post('/addRawMaterial', async (req, res) => {
  const { prodCode, prodName, qty, modifyDate } = req.body;

  const sql = 'UPDATE raw_material SET qty=qty+?, modifyDate=? WHERE prodCode=? AND prodName=?';
  const values = [qty, modifyDate, prodCode, prodName];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating raw_material entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('raw_material updated successfully');
    }
  });
});
app.post('/purchase_entry_item', (req, res) => {
  const { dataToInsertSupItem2 } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO purchase SET ?'; // Modify to your table name
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
app.get('/check_duplicate_poNo', (req, res) => {
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
app.get('/fetch_po_datas', (req, res) => {
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


app.get('/fetch_supplier', (req, res) => {
  const sql = 'SELECT * FROM supplier';
  db.query(sql, (err, result) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      console.log('supplier data successfully');
      res.status(200).json(result);
    }
  });
});
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
app.get('/get_purchase', (req, res) => {
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
app.get('/get_invoice_data', (req, res) => {
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

  const sql = `SELECT * FROM purchase WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/get_preturn', (req, res) => {
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
app.get('/getmachname', (req, res) => {
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
*/
/*app.post('/sales_return_update_Production', async (req, res) => {
  const { itemGroup, itemName, size, color, qty } = req.body;
  const sql = 'UPDATE production_entry SET  qty=qty+? WHERE itemGroup=? AND itemName=? AND size=? AND color=?';
  const values = [qty, itemGroup, itemName, size, color];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production_entry entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('production_entry updated successfully');
    }
  });
});*//*

*/
/*app.put('/sales_return_update_Production/update/:itemGroup/:itemName/size:/color', (req, res) => {
  const itemGroup = req.params.itemGroup;
  const itemName = req.params.itemName;
  const size = req.params.size;
  const color = req.params.color;
  const { saleInvNo,qtyIncrement } = req.body;

  console.log('Values before update:', req.body);
  const sql = 'UPDATE production_entry SET saleInvNo=?, qty=qty+? WHERE itemGroup=? AND itemName=? AND size=? AND color=?';
  const values = [saleInvNo, qtyIncrement, itemGroup, itemName, color, size];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating production entry:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Production updated successfully');
    }
  });
});*//*


*/
/*app.post('/sales_ret_mismatch', (req, res) => {
  const { dataToInsertMismatch } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO salesret_mismatch SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertMismatch], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});
app.post('/sales_ret_damage', (req, res) => {
  const { dataToInsertDamage } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO salesret_damage SET ?'; // Modify to your table name
  db.query(sql, [dataToInsertDamage], (err, result) => { // Wrap dataToInsert in an array
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
    }
  });
});*//*

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
app.get('/get_sales_return_report', (req, res) => {
  const sql = `select  s.invoiceNo,  s.salRetNo,  s.custCode,  s.date,  s.grandTotal, s. saleInvNo,  s.itemGroup, s. itemName,  s.qty,  s.rate,  s.amt,  s.amtGST,  s.total,  s.reason, c.custName, c.custAddress,c.custMobile
   from sales_returns s
   left join customer c on s.custCode = c.custCode`;

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/sales_item_view', (req, res) => {
  const invoiceNo = req.query.invoiceNo;

  const sql = `SELECT * FROM sales WHERE invoiceNo = ?`;

  db.query(sql, [invoiceNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});
app.get('/sales_retuen_item_view', (req, res) => {
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

  const sql = `SELECT * FROM prodcode_entry WHERE prodName = ?`;

  db.query(sql, [prodCode], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
  });
});

app.put('/product_update/:id', (req, res) => {
  const id = req.params.id;
  const prodName = req.body.prodName;
  const modifyDate = req.body.modifyDate;

  // Check if the prodName already exists in the database
  const checkQuery = 'SELECT * FROM prodcode_entry WHERE prodName = ?';
  db.query(checkQuery, [prodName], (checkErr, checkResult) => {
    if (checkErr) {
      throw checkErr;
    }

    if (checkResult.length > 0) {
      // ProdName already exists, return a 409 (Conflict) status code
      res.status(409).json({ message: 'Product name already exists' });
    } else {
      // Update the record
      const updateQuery = 'UPDATE prodcode_entry SET prodName = ?, modifyDate = ? WHERE id = ?';
      db.query(updateQuery, [prodName, modifyDate, id], (updateErr, updateResult) => {
        if (updateErr) {
          throw updateErr;
        }
        res.status(200).json({ message: 'Product code updated successfully' });
      });
    }
  });
});
app.put('/supplier_edit_update/:id', (req, res) => {
  const id = req.params.id;
  const supName = req.body.supName;
  const supAddress = req.body.supAddress;
  const supMobile = req.body.supMobile;
  const modifyDate = req.body.modifyDate;


  const checkQuery = 'SELECT * FROM supplier WHERE supName = ?';
  db.query(checkQuery, [supName], (checkErr, checkResult) => {
    if (checkErr) {
      throw checkErr;
    }

    if (checkResult.length > 0) {
        res.status(409).json({ message: 'supplier name already exists' });
    } else {
      // Update the record
      const updateQuery = 'UPDATE supplier SET supName = ?,supAddress = ?,supMobile = ?, modifyDate = ? WHERE id = ?';
      db.query(updateQuery, [supName, supAddress, supMobile, modifyDate, id], (updateErr, updateResult) => {
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


//end elango





//start bhuvana

app.delete('/item_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'DELETE FROM item WHERE id = ?';
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
//winding_entry
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
app.get('/winding_entry_get_report', (req, res) => {
  const sql = 'SELECT id, machName, assOne,assTwo,assThree,opOneName,optwoName,shiftType,date FROM winding_entry'; // Select only id and unit fields
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
app.get('/finishing_entry_get_report', (req, res) => {
  const sql = 'SELECT id, machName, assOne,assTwo,assThree,opOneName,optwoName,shiftType,date FROM finishing_entry'; // Select only id and unit fields
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
//app.get('/sales_item_view', (req, res) => {
//  const invoiceNo = req.query.invoiceNo;
//
//  const sql = `SELECT * FROM sales_item WHERE invoiceNo = ?`;
//
//  db.query(sql, [invoiceNo], (err, result) => {
//    if (err) {
//      throw err;
//    }
//    res.json(result);
//  });
//});
//app.post('/tosales_item', (req, res) => {
//  const { dataToInsertitem } = req.body;
//  const sql = 'INSERT INTO sales_item SET ?';
//  db.query(sql, [dataToInsertitem], (err, result) => {
//    if (err) {
//      console.error('Error Table inserting data:', err);
//      res.status(500).json({ error: 'Error Table inserting data' });
//    } else {
//      console.log('Table Data inserted successfully');
//      res.status(200).json({ message: 'Table Data inserted successfully' });
//    }
//  });
//});


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
  const sql = 'SELECT id, unit FROM unit_entry'; // Select only id and unit fields
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

app.post('/item_Name_entry', (req, res) => {
  const { dataToInsertitem } = req.body; // Assuming you send the data to insert in the request body

  const sql = 'INSERT INTO item_name SET ?'; // Modify to your table name

  db.query(sql, dataToInsertitem, (err, result) => {
    if (err) {
      console.error('Error inserting data:', err);
      res.status(500).json({ error: 'Error inserting data' });
    } else {
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data inserted successfully' });
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
app.get('/getallitemName', (req, res) => {
  const sql = 'SELECT * FROM item_Name'; // Modify to your table name

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/getitemname', (req, res) => {
  const sql = 'SELECT itemName FROM item order by itemName'; // Modify to your table name

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
app.get('/get_sales_name', (req, res) => {
 const sql = 'SELECT * FROM purchase_order';
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
app.get('/get_sales_items', (req, res) => {
  const orderNo = req.query.orderNo;

  const sql = `SELECT p.custName,p.custCode,p.orderNo,p.deliveryType,p.itemGroup,p.itemName,p.size,p.color,p.qty,i.rate,i.unit,i.gst FROM purchase_order p
                 LEFT JOIN item i ON p.itemGroup=i.itemGroup AND p.itemName=i.itemName AND p.size = i.size AND p.color = i.color
                 WHERE orderNo = ?`;

  db.query(sql, [orderNo], (err, result) => {
    if (err) {
      throw err;
    }
    res.json(result);
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
app.post('/sales_insert', (req, res) => {
  const { dataToInsertPurchaseReturnItem } = req.body; // Assuming you send the data to insert in the request body
  const sql = 'INSERT INTO sales SET ?'; // Modify to your table name
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


app.get('/production_entry_get_report', (req, res) => {
  const sql = 'SELECT id, machineName, itemGroup, itemName, size, color, qty, date FROM production_entry'; // Select only id and unit fields
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
 const sql ='SELECT * FROM stock';
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      res.status(500).json({ error: 'Error fetching data' });
    } else {
      res.status(200).json(results);
    }
  });
});

///Stock report
app.get('/stock_overall_get_report', (req, res) => {
//  const sql = 'SELECT id, machineName, itemGroup, itemName, size, color, qty, date FROM production_entry'; // Select only id and unit fields
 const sql ='SELECT * FROM stock';
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

app.put('/employee/update/:empID', (req, res) => {
  const empID = req.params.empID;
  const employeeData = req.body;

  // Ensure that 'gender' is provided and not null
  if (employeeData.gender === undefined || employeeData.gender === null) {
    return res.status(400).send('Gender cannot be null');
  }
  console.log('Values before update:', employeeData);
  const sql = 'UPDATE employee SET ? WHERE empID=?';
  // Use the spread operator to include all properties of employeeData
  const values = [{...employeeData}, empID];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating employee:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Employee updated successfully');
    }
  });
});
*/
/*
app.put('/employee/update/:empID', (req, res) => {
  const empID = req.params.empID;
  const { empName, empMobile, empAddress,bloodgroup,gender,maritalStatus,education,deptName,empPosition,salary,shift,acNumber,acHoldername,branch,ifsc,pan,bank } = req.body;

 if (gender === null || gender === undefined) {
    return res.status(400).send('Gender cannot be null');
  }
   const updatedAcHoldername = acHoldername === null || acHoldername === undefined ? '' : acHoldername;


  console.log('Values before update:', req.body);

  const sql = 'UPDATE employee SET empName=?, empMobile=?, empAddress=?,bloodgroup=?,gender=?,maritalStatus=?,education=?,deptName=?,empPosition=?,salary=?,shift=?,acNumber=?,acHoldername=?,branch=?,ifsc=?,pan=?,bank=? WHERE empID=?';
  const values = [empName, empMobile, empAddress,bloodgroup,gender,maritalStatus,education,deptName,empPosition,salary,shift,acNumber,acHoldername,branch,ifsc,pan,bank, empID];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error('Error updating employee:', err);
      res.status(500).send('Internal Server Error');
    } else {
      res.send('Employee updated successfully');
    }
  });
});
*//*


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

app.put('/employeeview_update/:id', (req, res) => {
  const { id } = req.params;
  const { empID, empName, empMobile, deptName, salary, empPosition } = req.body;
  const modifyDate = new Date(); // Add this line to get the current date and time

  const sql = 'UPDATE employee SET empID = ?, empName = ?, empMobile = ?, deptName = ?, salary = ?, empPosition = ?, modifyDate = ? WHERE id = ?';
  const values = [empID, empName, empMobile, deptName, salary, empPosition, modifyDate, id];

  db.query(sql, values, (err, results) => {
    if (err) {
      console.error('Error updating data:', err);
      res.status(500).json({ error: 'Error updating data' });
    } else {
      res.status(200).json({ message: 'Data updated successfully' });
    }
  });
});

app.delete('/employeeviewdelete/:id', (req, res) => {
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

app.get('/employeedublicate', (req, res) => {
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

app.get('/employeebyname/:empName', (req, res) => {
  const empName = req.params.empName;

  const query = 'SELECT * FROM employee WHERE empName = ?';

  db.query(query, [empName], (err, results) => {
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

app.delete('/items_delete/:id', (req, res) => {
  const { id } = req.params;

  const sql = 'delete from item where id = ?';
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
//production entry report
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

//stock report
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

// Starting the server
app.listen(app.get('port'), () => {
  console.log('Server on port', app.get('port'));
});
*/
