// Conectar al WebSocket
const socket = new WebSocket("ws://localhost:8765");

// Elemento del DOM
const statusDiv = document.getElementById("status");

// Cuando llega un mensaje
socket.onmessage = (event) => {
    const data = JSON.parse(event.data);
    updateUI(data.status);
};

// Actualizar UI
function updateUI(status) {
    statusDiv.textContent = status;
    statusDiv.className = status ? "true" : "false";
}

// Cambiar estado vía API
function setStatus(value) {
    fetch(`http://localhost:5000/set_status?value=${value}`)
        .then(res => res.json())
        .then(data => {
            console.log("Actualizado:", data);
        });
}

// Obtener estado inicial
fetch("http://localhost:5000/status")
    .then(res => res.json())
    .then(data => {
        updateUI(data.status);
    });