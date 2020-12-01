using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using Microsoft.EntityFrameworkCore;
using ProjectApi.Models;
using ProjectApi.CustomOptions;
using System.Data.SqlClient;
using System;

namespace ProjectApi
{
  public class Startup
  {
    public Startup(IConfiguration configuration)
    {
      Configuration = configuration;
    }

    public static IConfiguration Configuration { get; private set; }

    // This method gets called by the runtime. Use this method to add services to the container.
    public void ConfigureServices(IServiceCollection services)
    {
      services.Configure<VaultOptions>(Configuration.GetSection("Vault"));

      var dbBuilder = new SqlConnectionStringBuilder(
        Configuration.GetConnectionString("Database")
      );

      if (Configuration["database:userID"] != null) {
        dbBuilder.UserID = Configuration["database:userID"];
        dbBuilder.Password = Configuration["database:password"];

        Configuration.GetSection("ConnectionStrings")["Database"] = dbBuilder.ConnectionString;
      }

      services.AddDbContext<ProjectContext>(opt =>
          opt.UseSqlServer(Configuration.GetConnectionString("Database")));
      services.AddControllers();
      services.AddSwaggerGen(c =>
      {
        c.SwaggerDoc("v1", new OpenApiInfo { Title = "ProjectApi", Version = "v1" });
      });
    }

    // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
      if (env.IsDevelopment())
      {
        app.UseDeveloperExceptionPage();
        app.UseSwagger();
        app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "ProjectApi v1"));
      }

      app.UseHttpsRedirection();

      app.UseRouting();

      app.UseAuthorization();

      app.UseEndpoints(endpoints =>
      {
        endpoints.MapControllers();
      });
    }
  }
}
