// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');

AWS.config.update({region: 'REGION'});

// Create the DynamoDB service object
var ddb = new AWS.DynamoDB({apiVersion: '2012-08-10'});


// function getItem(readParams){
    
//   db.get(readParams, (err, data) => {
//   if (err){
//     console.log("Error:", err);
//   } 
//   else{
//     console.log("Success:", data.Item);
    
//   } 
//   console.log("Completed call");
// });

// }


// const db = new AWS.DynamoDB.DocumentClient({
//   region : 'us-east-1' 
// })

exports.handler =  async function(event, context) {
    console.log("EVENT: \n" + JSON.stringify(event, null, 2))
    const snsMsg = event.Records[0].Sns.Message;
    var userEmail = snsMsg.split(':')[0];
    var resetToken = snsMsg.split(':')[1];
    var ttl = snsMsg.split(':')[2];
    
    var readParams = {
      TableName: 'csye6225',
      Key: {
        'emailId': {S: userEmail}
      }
    };
    var writeParams = {
      TableName: 'csye6225',
      Item: {
        'emailId' : {S: userEmail},
        'token' : {S: resetToken},
        'ttl':{N: ttl}
      }
    };
    console.log("why")
    // getItem(readParams);

    

    
    // Call DynamoDB to read the item from the table
    ddb.getItem(readParams, function(err, data) {
      console.log("exeeeee")
      if (err) {
        
        console.log("read err")
        console.log("Error", err);
        // Call DynamoDB to add the item to the table
        // ddb.putItem(writeParams, function(err, data) {
        //   if (err) {
        //     console.log("Error", err);
        //   } else {
        //     console.log("Success", data);
        //   }
        // });
        
      } else {
        console.log("read succ")
        console.log("Success", data.Item);
      }
    });
    
    // console.log(sns)
 
    // return context.logStreamName
  }