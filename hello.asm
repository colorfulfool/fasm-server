format ELF64 executable

AF_INET = 2
SOCK_STREAM = 1
INADDR_ANY = 0
SOL_SOCKET = 1
SO_REUSEADDR = 2

MAX_CONN equ 1000
REQUEST_CAP equ 128*1024

macro write fd, buf, count {
  mov rax, 1
  mov rdi, fd
  mov rsi, buf
  mov rdx, count
  syscall
}

macro exit status {
  mov rax, 60
  mov rdi, status
  syscall
}

macro socket domain, type, protocol {
  mov rax, 41
  mov rdi, domain
  mov rsi, type
  mov rdx, protocol
  syscall
}

macro setsockopt sockfd, level, optname, optval, optlen {
  mov rax, 54
  mov rdi, sockfd
  mov rsi, level
  mov rdx, optname
  mov r10, optval
  mov r8, optlen
  syscall
}

macro bind sockfd, addr, addr_len {
  mov rax, 49
  mov rdi, sockfd
  mov rsi, addr
  mov rdx, addr_len
  syscall
}

macro listen sockfd, backlog {
  mov rax, 50
  mov rdi, sockfd
  mov rsi, backlog
  syscall
}

macro accept sockfd, addr, addrlen {
  mov rax, 43
  mov rdi, sockfd
  mov rsi, addr
  mov rdx, addrlen
  syscall
}

macro read fildes, buf, nbyte {
  mov rax, 0
  mov rdi, fildes
  mov rsi, buf
  mov rdx, nbyte
  syscall
}

macro close sockfd {
  mov rax, 3
  mov rdi, sockfd
  syscall
}

segment readable executable
entry main
main:
  write 1, start, start_len

  write 1, create_socket_msg, create_socket_msg_len
  socket AF_INET, SOCK_STREAM, 0
  cmp rax, 0
  jl error
  mov qword [sockfd], rax

  setsockopt [sockfd], SOL_SOCKET, SO_REUSEADDR, one, 4
  cmp rax, 0
  jl error

  write 1, bind_socket_msg, bind_socket_msg_len
  mov word [sockaddr.sin_family], AF_INET
  mov word [sockaddr.sin_port], 14619
  mov dword [sockaddr.sin_addr], INADDR_ANY
  bind [sockfd], sockaddr.sin_family, sockaddr.size
  cmp rax, 0
  jl error

  write 1, listen_socket_msg, listen_socket_msg_len
  listen [sockfd], MAX_CONN
  cmp rax, 0
  jl error

next_request:
  write 1, accept_socket_msg, accept_socket_msg_len
  accept [sockfd], cliaddr, cliaddr_len
  cmp rax, 0
  jl error

  mov qword [connfd], rax

  read [connfd], request, REQUEST_CAP
  cmp rax, 0
  jl error
  mov [request_len], rax

  mov [request_cur], request

  ; write 1, [request_cur], [request_len]

  mov rbx, [request_cur]
  add rbx, 5

  cmp byte [rbx], 'f'
  je respond_with_svg

  write [connfd], response, response_len
  close [connfd]
  jmp next_request

respond_with_svg:
  write [connfd], response_svg, response_svg_len
  close [connfd]
  jmp next_request
  
  close [sockfd]
  close [connfd]
  exit 0

error:
  write 2, error_msg, error_msg_len
  close [sockfd]
  close [connfd]
  exit 1

segment readable writable

struc sockaddr_in {
  .sin_family dw 0
  .sin_port   dw 0
  .sin_addr   dd 0
  .sin_zero   dq 0
  .size = $ - .sin_family
}

sockfd dq -1
connfd dq -1
one dd 1
sockaddr sockaddr_in
cliaddr sockaddr_in
cliaddr_len dd cliaddr.size

hello db "Hello from flat assembler!", 10
hello_len = $ - hello

request_len rq 1
request_cur rq 1
request     rb REQUEST_CAP

response db "HTTP/1.1 200 OK", 13, 10
         db "Content-Type: text/html", 13, 10
         db "Connection: close", 13, 10
         db 13, 10
         db "<h1>Hellow from flat assembler!</h1>", 10
response_len = $ - response

response_svg db "HTTP/1.1 200 OK", 13, 10
             db "Content-Type: image/svg+xml", 13, 10
             db "Connection: close", 13, 10
             db 13, 10
             db "<svg width='16' height='16' fill='none' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'>", 10
             db "<circle cx='50' cy='50' r='30' stroke='firebrick' stroke-width='10' />", 10
             db "</svg>", 10
response_svg_len = $ - response_svg

start db "Starting web server...", 10
start_len = $ - start
create_socket_msg db "Creating a socket...", 10
create_socket_msg_len = $ - create_socket_msg
bind_socket_msg db "Binding address to the socket...", 10
bind_socket_msg_len = $ - bind_socket_msg
listen_socket_msg db "Listening on the socket...", 10
listen_socket_msg_len = $ - listen_socket_msg
accept_socket_msg db "Waiting for client connections...", 10
accept_socket_msg_len = $ - accept_socket_msg
error_msg db "Error.", 10
error_msg_len = $ - error_msg
