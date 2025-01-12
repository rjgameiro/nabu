pub mod server;

use serde::{Serialize, Deserialize};

// Query parameters struct
#[derive(Deserialize, Debug)]
pub struct TextQuery {
    pub text: Option<String>,
}

// Define the JSON response structure
#[derive(Serialize, Debug)]
pub struct MessageResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}
