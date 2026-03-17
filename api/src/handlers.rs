use crate::models::*;
use actix_web::{HttpResponse, Responder, get};
use oracle::Connection;
use std::env;

fn establish_connection() -> Connection {
    let user = env::var("DB_USER").unwrap_or_else(|_| "system".to_string());
    let pass = env::var("DB_PASSWORD").unwrap_or_else(|_| "oraclepass".to_string());
    let conn_str =
        env::var("DB_CONNECT_STRING").unwrap_or_else(|_| "//localhost:1521/XE".to_string());
    Connection::connect(user, pass, conn_str).expect("Échec connexion Oracle")
}

#[get("/clients")]
pub async fn get_clients() -> impl Responder {
    let conn = establish_connection();
    let rows = conn
        .query(
            "SELECT id, name, email, phone FROM CLIENTS ORDER BY id",
            &[],
        )
        .unwrap();
    let data: Vec<Client> = rows
        .filter_map(|r| r.ok())
        .map(|row| Client {
            id: row.get(0).unwrap(),
            name: row.get(1).unwrap(),
            email: row.get(2).unwrap(),
            phone: row.get(3).unwrap(),
        })
        .collect();
    HttpResponse::Ok().json(data)
}

#[get("/contacts")]
pub async fn get_contacts() -> impl Responder {
    let conn = establish_connection();
    let rows = conn
        .query("SELECT id, name, email, client_id FROM CONTACTS", &[])
        .unwrap();
    let data: Vec<Contact> = rows
        .filter_map(|r| r.ok())
        .map(|row| Contact {
            id: row.get(0).unwrap(),
            name: row.get(1).unwrap(),
            email: row.get(2).unwrap(),
            client_id: row.get(3).unwrap(),
        })
        .collect();
    HttpResponse::Ok().json(data)
}

#[get("/users")]
pub async fn get_users() -> impl Responder {
    let conn = establish_connection();
    let rows = conn
        .query("SELECT id, username, email, role FROM USERS", &[])
        .unwrap();
    let data: Vec<User> = rows
        .filter_map(|r| r.ok())
        .map(|row| User {
            id: row.get(0).unwrap(),
            username: row.get(1).unwrap(),
            email: row.get(2).unwrap(),
            role: row.get(3).unwrap(),
        })
        .collect();
    HttpResponse::Ok().json(data)
}

#[get("/deals")]
pub async fn get_deals() -> impl Responder {
    let conn = establish_connection();
    let rows = conn
        .query(
            "SELECT id, title, amount, status, client_id FROM DEALS",
            &[],
        )
        .unwrap();
    let data: Vec<Deal> = rows
        .filter_map(|r| r.ok())
        .map(|row| Deal {
            id: row.get(0).unwrap(),
            title: row.get(1).unwrap(),
            amount: row.get(2).unwrap(),
            status: row.get(3).unwrap(),
            client_id: row.get(4).unwrap(),
        })
        .collect();
    HttpResponse::Ok().json(data)
}

#[get("/tasks")]
pub async fn get_tasks() -> impl Responder {
    let conn = establish_connection();
    let rows = conn
        .query(
            "SELECT id, title, description, TO_CHAR(due_date, 'YYYY-MM-DD HH24:MI:SS') FROM TASKS",
            &[],
        )
        .unwrap();
    let data: Vec<Task> = rows
        .filter_map(|r| r.ok())
        .map(|row| Task {
            id: row.get(0).unwrap(),
            title: row.get(1).unwrap(),
            description: row.get(2).unwrap(),
            due_date: row.get(3).unwrap(),
        })
        .collect();
    HttpResponse::Ok().json(data)
}
