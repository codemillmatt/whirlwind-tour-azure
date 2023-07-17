using Microsoft.AspNetCore.SignalR;

namespace PizzaConf.Web.Data
{
    public class PizzaConfSignalRHub : Hub
    {        
        public async Task Broadcast(string name, string message)
        {
            await Clients.All.SendAsync("Broadcast", name, message);
        }

        public Task Echo(string name, string message) =>
            Clients.Client(Context.ConnectionId).SendAsync("echo", name, $"{message} from server");
    }
}
