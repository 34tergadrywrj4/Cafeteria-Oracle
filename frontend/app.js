const API_BASE = "http://127.0.0.1:8000";
let alumnos = [], empleados = [], productos = [], carrito = [];
const apiStatus = document.getElementById("apiStatus");
const alumnoSelect = document.getElementById("alumnoSelect");
const empleadoSelect = document.getElementById("empleadoSelect");
const productosGrid = document.getElementById("productosGrid");
const carritoDiv = document.getElementById("carrito");
const totalPedido = document.getElementById("totalPedido");
const pedidosBody = document.getElementById("pedidosBody");
const toast = document.getElementById("toast");
function money(value){return `$${Number(value||0).toFixed(2)}`}
function showToast(message){toast.textContent=message;toast.classList.remove("hidden");setTimeout(()=>toast.classList.add("hidden"),3500)}
async function apiFetch(path, options={}){const res=await fetch(`${API_BASE}${path}`,{headers:{"Content-Type":"application/json"},...options});if(!res.ok){const err=await res.json().catch(()=>({detail:"Error desconocido"}));throw new Error(err.detail||"Error en API")}return res.json()}
async function checkApi(){try{const data=await apiFetch("/api/health");apiStatus.textContent=`API: ${data.status}`;apiStatus.className="status ok"}catch(e){apiStatus.textContent="API: desconectada";apiStatus.className="status fail"}}
async function cargarDatos(){try{await checkApi();const data=await apiFetch("/api/catalogo");alumnos=data.alumnos;empleados=data.empleados;productos=data.productos;renderSelects();renderProductos();await cargarPedidos();showToast("Datos cargados desde Oracle")}catch(e){productosGrid.innerHTML=`<div class="loading">No se pudieron cargar datos: ${e.message}</div>`;showToast(`Error: ${e.message}`)}}
function renderSelects(){alumnoSelect.innerHTML=alumnos.map(a=>`<option value="${a.id_alumno}">${a.nombre} ${a.apellido||""} - ${a.carrera||"Sin carrera"}</option>`).join("");empleadoSelect.innerHTML=empleados.map(e=>`<option value="${e.id_empleado}">${e.nombre} - ${e.rol||"Empleado"}</option>`).join("")}
function renderProductos(){if(!productos.length){productosGrid.innerHTML=`<div class="loading">No hay productos disponibles</div>`;return}productosGrid.innerHTML=productos.map(p=>`<article class="product-card"><span class="cat">${p.categoria||"Producto"}</span><h4>${p.nombre}</h4><p>${money(p.precio)}</p><button class="small-btn" onclick="agregarProducto(${p.id_producto})">Agregar</button></article>`).join("")}
function agregarProducto(id){const p=productos.find(x=>Number(x.id_producto)===Number(id));if(!p)return;const item=carrito.find(x=>Number(x.id_producto)===Number(id));if(item)item.cantidad++;else carrito.push({...p,cantidad:1});renderCarrito()}
function quitarProducto(id){carrito=carrito.filter(x=>Number(x.id_producto)!==Number(id));renderCarrito()}
function totalCarrito(){return carrito.reduce((s,i)=>s+Number(i.precio)*i.cantidad,0)}
function renderCarrito(){if(!carrito.length){carritoDiv.className="empty-box";carritoDiv.innerHTML="No hay productos agregados.";totalPedido.textContent=money(0);return}carritoDiv.className="";carritoDiv.innerHTML=carrito.map(i=>`<div class="cart-item"><div><strong>${i.nombre}</strong><span>${i.cantidad} x ${money(i.precio)}</span></div><button class="small-btn danger" onclick="quitarProducto(${i.id_producto})">Quitar</button></div>`).join("");totalPedido.textContent=money(totalCarrito())}
async function crearPedido(){if(!carrito.length){showToast("Agrega al menos un producto");return}const payload={id_alumno:Number(alumnoSelect.value),id_empleado:Number(empleadoSelect.value),productos:carrito.map(i=>({id_producto:Number(i.id_producto),cantidad:Number(i.cantidad)}))};try{const result=await apiFetch("/api/pedidos",{method:"POST",body:JSON.stringify(payload)});carrito=[];renderCarrito();showToast(`Pedido #${result.id_pedido} creado y enviado a RabbitMQ`);await cargarPedidos()}catch(e){showToast(`No se pudo crear el pedido: ${e.message}`)}}
async function cargarPedidos(){try{const pedidos=await apiFetch("/api/pedidos");if(!pedidos.length){pedidosBody.innerHTML=`<tr><td colspan="6" class="empty-cell">Todavía no hay pedidos</td></tr>`;return}pedidosBody.innerHTML=pedidos.map(p=>`<tr><td>#${p.id_pedido}</td><td>${p.alumno||"-"}</td><td>${p.empleado||"-"}</td><td>${money(p.total)}</td><td><span class="estado ${p.estado}">${p.estado}</span></td><td>${(p.productos||[]).join("<br>")||"-"}</td></tr>`).join("")}catch(e){pedidosBody.innerHTML=`<tr><td colspan="6" class="empty-cell">Error al cargar pedidos: ${e.message}</td></tr>`}}
document.getElementById("btnCrearPedido").addEventListener("click",crearPedido);
document.getElementById("btnLimpiar").addEventListener("click",()=>{carrito=[];renderCarrito()});
document.getElementById("btnReload").addEventListener("click",cargarDatos);
document.getElementById("btnPedidos").addEventListener("click",cargarPedidos);
renderCarrito();cargarDatos();setInterval(cargarPedidos,4000);
