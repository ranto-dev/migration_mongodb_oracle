mod handlers;
mod models;

use actix_web::{App, HttpServer, web};
use dotenv::dotenv;
use handlers::*;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    println!("API démarrée sur http://localhost:8080/api/");

    HttpServer::new(|| {
        App::new().service(
            web::scope("/api")
                .service(get_clients)
                .service(get_contacts)
                .service(get_users)
                .service(get_deals)
                .service(get_tasks),
        )
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
