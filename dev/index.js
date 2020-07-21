exports.handler =  async function(event, context) {
    console.log("EVENT: \n" + JSON.stringify(event, null, 2))
    var snsMessage = event.Records[0].Sns.Message;
    console.log(snsMessage);
    return context.logStreamName
  }