using System.Text.Json;
using System.Threading.Tasks;
using Amazon.Lambda.Core;
using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace SendUpdateNotifications
{
    public class Function
    {
        private readonly IAmazonSimpleNotificationService _snsClient;

        public Function()
        {
            _snsClient = new AmazonSimpleNotificationServiceClient();
        }

        // Handler padrão: recebe um objeto de entrada e publica dois payloads diferentes em dois tópicos SNS
        public async Task<object> FunctionHandler(object input, ILambdaContext context)
        {
            var userTopicArn = System.Environment.GetEnvironmentVariable("USER_TOPIC_ARN");
            var productsTopicArn = System.Environment.GetEnvironmentVariable("PRODUCTS_TOPIC_ARN");

            var userPayload = JsonSerializer.Serialize(new { type = "user", payload = input });
            var productsPayload = JsonSerializer.Serialize(new { type = "products", payload = input });

            if (!string.IsNullOrEmpty(userTopicArn))
            {
                await _snsClient.PublishAsync(new PublishRequest
                {
                    TopicArn = userTopicArn,
                    Message = userPayload
                });
            }

            if (!string.IsNullOrEmpty(productsTopicArn))
            {
                await _snsClient.PublishAsync(new PublishRequest
                {
                    TopicArn = productsTopicArn,
                    Message = productsPayload
                });
            }

            return new { status = "published", userTopic = userTopicArn, productsTopic = productsTopicArn };
        }
    }
}
