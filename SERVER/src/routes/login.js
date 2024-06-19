   const { Router } = require('express');
   const router = Router();

   const mysqlConnection = require('../database');

   router.get('/', (req, res) => {
       res.status(200).json('Server on port 4000 and Database is connected.');
   });

  /* router.post('/:login', (req, res) => {
       const {custCode,custName,custAddress,custMobile,custGSTIN,custPaytype} = req.body;
       console.log(req.body);
       mysqlConnection.query('insert into customer (custCode,custName,custAddress,custMobile,custGSTIN,custPaytype) values (?,?,?,?,?,?)', [custCode,custName,custAddress,custMobile,custGSTIN,custPaytype], (error, rows, fields) => {
           if(!error) {
               res.json({Status : "User saved"})
           } else {
               console.log(error);
           }
       });
   });*/

    router.get('/:login', (req, res) => {
        mysqlConnection.query('select * from supplier order by supCode desc limit 1', (error, rows, fields) => {
            if(!error) {
                res.json(rows);
            } else {
                console.log(error);
            }
        });
    });


    /*router.post('/:login', (req, res) => {
          const {from, to, empID, empName, shiftType, shiftTime, ot} = req.body;
          console.log(req.body);
          mysqlConnection.query('insert into shift (from, to, empID, empName, shiftType, shiftTime, ot) values (?,?,?,?,?,?,?)', [from, to, empID, empName, shiftType, shiftTime, ot], (error, rows, fields) => {
              if(!error) {
                  res.json({Status : "User saved"})
              } else {
                  console.log(error);
              }
          });
      });*/

  //custCode
   router.get('/:login', (req, res) => {
       mysqlConnection.query('select * from customer order by custCode desc limit 1', (error, rows, fields) => {
           if(!error) {
               res.json(rows);
           } else {
               console.log(error);
           }
       });
   });

   //supcode get
  router.get('/:login', (req, res) => {
       mysqlConnection.query('select * from supplier order by supCode desc limit 1', (error, rows, fields) => {
           if(!error) {
               res.json(rows);
           } else {
               console.log(error);
           }
       });
   });

   router.get('/:login/:id', (req, res) => {
       const { id } = req.params;
       mysqlConnection.query('select * from from login_user where id = ?', [id], (error, rows, fields) => {
           if(!error) {
               res.json(rows);
           } else {
               console.log(error);
           }
       })
   });


//   router.post('/:login', (req, res) => {
//       const { username,password} = req.body;
//       console.log(req.body);
//       mysqlConnection.query('insert into login_user (username,password) values (?,?)', [username,password], (error, rows, fields) => {
//           if(!error) {
//               res.json({Status : "User saved"})
//           } else {
//               console.log(error);
//           }
//       });
//   });

  /* router.post('/:login', (req, res) => {
       const {supCode,supName,supAddress,supMobile,supGSTIN,supPaytype} = req.body;
       console.log(req.body);
       mysqlConnection.query('insert into supplier (supCode,supName,supAddress,supMobile,supGSTIN,supPaytype) values (?,?,?,?,?,?)', [supCode,supName,supAddress,supMobile,supGSTIN,supPaytype], (error, rows, fields) => {
           if(!error) {
               res.json({Status : "User saved"})
           } else {
               console.log(error);
           }
       });
   });*/

   router.put('/:login/:id', (req, res) => {
       const { id, username, name, lastname, mail, randomstr, hash } = req.body;
       console.log(req.body);
       mysqlConnection.query('update from login_user set username = ?,password = ?, where id = ?;',
       [username,password], (error, rows, fields) => {
           if(!error){
               res.json({
                   Status: 'User updated'
               });
           } else {
               console.log(error);
           }
       });
   });

   router.delete('/:login/:id', (req,res) => {
       const { id } = req.params;
       mysqlConnection.query('delete from login_user where id = ?', [id], (error, rows, fields) => {
           if(!error){
               res.json({
                   Status: "User deleted"
               });
           } else {
               res.json({
                   Status: error
               });
           }
       })
   });

   module.exports = router;