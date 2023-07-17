using Azure.Identity;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Web;
using PizzaConf.Web.Data;

using Microsoft.Extensions.Configuration.AzureAppConfiguration;

using Microsoft.Extensions.Azure;
using Azure.Core.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();
builder.Services.AddSingleton<PizzaWebService>();
builder.Services.AddSingleton<CartWebService>();

//TODO: Uncomment when implementing SignalR
//builder.Services.AddSignalR().AddAzureSignalR(options =>
//{
//    options.ServerStickyMode = Microsoft.Azure.SignalR.ServerStickyMode.Required;
//    options.ConnectionString = builder.Configuration["Azure:SignalR:ConnectionString"];
//});

builder.Services.AddHttpClient<PizzaWebService>(client =>
{
    string url = builder.Configuration["menuUrl"] ?? "http://localhost:3500";
    Uri baseAddress = new(url);

    client.BaseAddress = baseAddress;
});

builder.Services.AddHttpClient<CartWebService>(client =>
{
    string url = builder.Configuration["cartUrl"] ?? "http://localhost:3500";
    Uri baseAddress = new(url);
        
    client.BaseAddress = baseAddress;
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

//TODO: Uncomment when implementing SignalR
//app.MapHub<PizzaConfSignalRHub>("/PizzaConfSignalRHub");

app.MapBlazorHub();

app.MapFallbackToPage("/_Host");

app.Run();
