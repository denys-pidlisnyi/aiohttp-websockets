import socket

import aiohttp
from aiohttp import web


host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)


async def welcome(request):
    return web.Response(text=f"Welcome! hostname: {host_name}, ip: {host_ip}")


async def websocket_handler(request):

    ws = web.WebSocketResponse()
    await ws.prepare(request)

    async for msg in ws:
        if msg.type == aiohttp.WSMsgType.TEXT:
            if msg.data == 'close':
                await ws.send_str('goodbye')
                await ws.close()
            else:
                await ws.send_str(msg.data + f'/answer hostname: {host_name}, ip: {host_ip}')
        elif msg.type == aiohttp.WSMsgType.ERROR:
            print('ws connection closed with exception %s' % ws.exception())

    print('websocket connection closed')

    return ws


def create_app():
    app = web.Application()
    app.add_routes([web.get('/', welcome)])
    app.add_routes([web.get('/ws/', websocket_handler)])
    return app
