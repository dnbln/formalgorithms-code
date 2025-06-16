use tokio::io::{AsyncReadExt, AsyncWriteExt};

async fn socket_future(mut socket: tokio::net::TcpStream) {
    // Simulate some work with the socket
    let mut buf = [0; 8192];
    loop {
        // let r = socket.ready(tokio::io::Interest::READABLE).await.unwrap();
        // if r.is_read_closed() {
        //     break;
        // }
        let r = socket.read(&mut buf).await.unwrap();
        if r == 0 {
            break;
        }

        socket.write_all(&buf[..r]).await.unwrap();
    }

    socket.shutdown().await.unwrap();
}

#[tokio::main]
async fn main() {
    let tcp_listener = tokio::net::TcpListener::bind(("127.0.0.1", 8080)).await.unwrap();
    loop {
        let (socket, _) = tcp_listener.accept().await.unwrap();
        tokio::spawn(socket_future(socket));
    }
}