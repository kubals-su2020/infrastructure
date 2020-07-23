var aws = require('aws-sdk');
// var ses = new aws.SES({region: 'us-west-2'});
var domainName = process.env.DOMAIN;
var sourceEmailId = process.env.SOURCE;
var ddb = new aws.DynamoDB({params: {TableName: 'csye6225'}});

exports.handler = function(event, context) {

    console.log("EVENT: \n" + JSON.stringify(event, null, 2))
    const snsMsg = event.Records[0].Sns.Message;
    var userEmail = snsMsg.split(':')[0];
    var resetToken = snsMsg.split(':')[1];
    var ttl = snsMsg.split(':')[2];
    var temttl= Math.floor(Date.now() / 1000) + 900;
    console.log(temttl)
    var readParams = {
      TableName: 'csye6225',
      Key: {
        'id': {S: userEmail}
      }
    };

    var writeParams = {
      TableName: 'csye6225',
      Item: {
        'id' : {S: userEmail},
        'token' : {S: resetToken},
        'ttl':{N: temttl.toString()}
      }
    };
    
    
    
    //get item from dynamodb
    ddb.getItem(readParams, function(err, data) {
      if (err) {
        console.log("Error getting item", err);
      }
      else {
        console.log(data)
          if(Object.keys(data).length>0){
            console.log("Success getting item:", data.Item);
          }
          else{
            console.log("Success getting, but no item ");
            // put item to DynamoDB 
            ddb.putItem(writeParams, function(err, data) {
              if (err) {
                console.log("Error putting item", err);
              } else {
                 const params = {
                  Destination: {
                    ToAddresses: [userEmail]
                  },
                  Message: {
                    Body: {
                      Text: {
                        Charset: "UTF-8",
                        Data: 'http://'+domainName+'/reset?email='+userEmail+'&token='+resetToken
                      }
                    },
                    Subject: {
                      Charset: "UTF-8",
                      Data: "Password Reset Link"
                    }
                  },
                  Source: sourceEmailId
                };
                // Create the promise and SES service object
                var sendPromise = new aws.SES({apiVersion: '2010-12-01'}).sendEmail(params).promise();

                // Handle promise's fulfilled/rejected states
                sendPromise.then(
                  function(data) {
                    console.log(data.MessageId);
                  }).catch(
                    function(err) {
                    console.error(err, err.stack);
                  });
                console.log("Success putting item:", data);
              }
            });
          }
      }
    });

};