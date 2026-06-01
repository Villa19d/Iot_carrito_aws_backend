class StatusController:
    def __init__(self, model, websocket_server):
        self.model = model
        self.websocket_server = websocket_server

    async def update_status(self, value: bool):
        data = self.model.set_status(value)

        # Notificar a todos los clientes WebSocket
        await self.websocket_server.broadcast(data)

        return data

    def get_status(self):
        return self.model.get_status()