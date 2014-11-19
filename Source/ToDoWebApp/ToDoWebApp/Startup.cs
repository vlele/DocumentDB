using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(ToDoWebApp.Startup))]
namespace ToDoWebApp
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
