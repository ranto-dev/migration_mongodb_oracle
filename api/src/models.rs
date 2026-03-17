use serde::Serialize;

#[derive(Serialize)]
pub struct Client {
    pub id: i32,
    pub name: String,
    pub email: String,
    pub phone: String,
}

#[derive(Serialize)]
pub struct Contact {
    pub id: String,
    pub name: String,
    pub email: String,
    pub client_id: i32,
}

#[derive(Serialize)]
pub struct User {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: String,
}

#[derive(Serialize)]
pub struct Deal {
    pub id: String,
    pub title: String,
    pub amount: f64,
    pub status: String,
    pub client_id: i32,
}

#[derive(Serialize)]
pub struct Task {
    pub id: String,
    pub title: String,
    pub description: String,
    pub due_date: String,
}
