/*Usa base de datos NorthWin para estos ejercicios*/

/*EJERCICOS de VISTAS*/

/*Ejercicio1
Si cada vendedor representa a una ciudad, que es a su vez la ciudad donde vive, calcula la cantidad de ordenes y el monto final sin descuento de cada ciudad*/
/*Crear una vista para mostrar el resultado del ejercicio*/
Create view Vendedor_Orden
as
Select e.city, count(o.OrderID) as "Cantidad de Ordenes", sum(od.Quality*od.UnitPrice) as "Monto sin Descuento" from Employees e inner join Orders o on e.EmployeeID=o.EmployeeID
inner join [ORder Details] od on o.OrderID = od.OrderID
group by e.City;

/*Ejercicio 2
Cual es el año en que se generaron más ventas? */

select top 1 with ties /*selecciona el primer valor*/ year(o.OrderDate) as "year" , sum(od.Quality*od.UnitPrice*(1-od.Discount /*multiplica por el descuento tambien*/)) as "Monto Total" from Orders o inner join [Order Details] od 
on o.OrderID=od.OrderID group by year(o.OrderDate) order by 2 desc /*descendente por columna 2*/

/*Ejercicio 3
Podemos decir que todos los productos se encutran en al menos 4 ordenes? */
Create view Ordenes_Productos as 
select p.ProductName, count(od.OrderID) as "Cantidad de Ordenes" from Products p inner join [Oderder Details] od on od.ProductID=p.ProductID
group by p.ProductName having count(od.OrderID) > 4

/*Ejercicio 4
Todos los vendedores han vendido al menos 100 unidades de algun producto en noviembre y diciembre de cualquier año?*/
select e.FirstName, p.ProductName, count(od.Quantity) as "Cantidades" from Employees e inner join Orders o on o.EmployeeID = o.EmployessID
inner join OrderDetails od on o.OrderID = od.OrderID
inner join Products p on p.ProductID=od.ProductID
where month(o.OrderDate)=11 or month(o.OrderDate)=12 group by e.FirstName, p.ProductName
having count(od.Quantity) >= 100

/*Ejercicio 5
Quienes son los vendeores que tuvieron menor tiempo de entrega de producto para todas las ventas (Por eso el sum en el datediff)*/
Create view Timpo_Entrega as
select e.FirstNme, e.LastName, sum(DATEDIFF(o.OrderDate, o.ShippedDate)) as "TiempoEntrega" /*DATEDIFF hace la diferencia entre dos fechas*/
from Employees e inner join Orders o on e.EmployeeID = o.EmployeeID
group by e.FirstName, e.LastName

Select min(v.TimepoEntrega) from Tiempo_Engrega v /*Este min lo puede llevar al select de la vista, y es lo mismo, min(sum(datediff(.....)))

/*EJERCICIOS de FUNCIONES*/

/*Ejercicio 1
Funcion para retornar la cantidad de ordenes en un determinado año y mes*/

create function Cuenta_Ordenes() returns int /*se le debe indicar el tipo de dato a retornar*/
as
begin
  declare @num_orden int
  select @num_ordern = count(o.OrderID) from Orders o
  where year(o.OrderDate) = 1998 and month(o.OrderDate) = 5 /*estos datos tienen que ser parámetros de entrada de la función */
  return @num_orden
end

print Cuenta_Ordenes()

/*Ejercicio 2
Crear funcion que devuelva la suma del monto total por un año, mes, dia en especifico*/

create function Suma_Total(@anio int, @mes int, @dia int) return float
as
begin
    declare @monto_total float
    select @monto=sum(od.Quantity*od.UnitPrice*(1- od.Discount)) 
    from Orders o inner join [Order Details] od on od.OrderID=o.OrderID
    where year(o.OrderDate)=@anio and month(o.OrderDate) = @mes and day(o.OrderDate) = @dia
    return @monto 
end

print dbo.Suma_Total(1997,2,25) /*Para ejecutar la funcion*/

/*Ejercicio 3
Funcion que devuelva como resultado una tabla con ordenes, fecha, shipped date y freight por un año, mes y dia especificos*/

create function ORdenes_Especiales(@anio int, @mes int, @dia int) 
return @tabla Table(OrderID int, OrderDate date, shippedDate date, freight float) /*Retorna una variale tabla del tipo TABLE para que ocntenga la tabla deseada*/
as
begin
 insert into @tabla
 select o.OrderID, o.OrderDate, o.ShippedDate, o.freight from Orders o
 where year(o.OrderDate)=@anio and month(o.OrderDate) = @mes and day(o.OrderDate) = @dia
 return /*para el caso que debe retornar una tabla, se pone retunr solo*/
end

Select a.* from Ordenes_Especiales(1997,2,15) a; /*en el form se pasa la funcion como parámetro ya que la funcion retorna una tabla*/

/*Ejercicio 4
Crear una funcion que retorne una tabla con codigo de vendedor que mas ventas tuvo en un periodo (fecha min y fecha max)*/
create function Mejor_Vendedor(@fecha_inicio date, @fecha_ultima date)
return @tabla TABLE(idvendedor int, ventas float) 
as
begin
 insert into @tabla
 select top 1 with ties /*Para decirle que seleccione las filas que tienen mismo valor*/ e.EmployeeID, sum(od.Quantity*od.UnitPrice*(1-Disccount)) as "Ventas" 
from Employees e inner join Orders o on o.EmployeeID = e.EmployeeID
 inner join OrderDetails od on od.OrderID=o.OrderID
 where o.OrderDate between @fecha_inicio and @fecha_ultima
 group by e.EmployeeID
 order by 2 desc
return
end

select a.* from Mejor_Vendedor('1996-07-04','1997-07-10') a;


/*Store Procedures o Procedimientos almacenados*/
/*La función se utiliza como metodo y el procedimiento se usa como script. La función siempre debe devolver un valor, pero un procedimiento
puede devolver valores nulos, ceros o valores especiales. El SP es m´´as usado que las funciones
No recibe parámetros pero si se pueden declarar variables*/

/*Ejericio1
Necesitamos crear un reporte que muestre cuales son las categorias que superan el promedio de ventas total
Nombre de la categoria y el monto ordenado de manera descendente por monto
Y la sentencia que invoca al reporte */

Create Procedure pCategorias_Promedio
as
 select c.CategorieName, c.CategorieID, c.V_CATEGORIA from categories c
 where c.V_CATEGORIA > (select avg(c1.V_CATEGORIA) from categories c1) /*V_CATEGORIA es el monto de la categoria*/
 order by 3 desc
go 

exec pCategorias_Promedio /*ejecuta el procedimiento*/

/*Ejercicio2
Relaizar un SP que devuelva el precio mayor y el precio menor según la categoria
Observar ambas tablas estan relacionadas por el campo CategoryID */

create Procedure spPrevioMayor_PrecioMenor
 @categoria_name varchar(100),
 @precio_mayor money output, /*output porque es la variable de salida del SP o del reporte*/
 @precio_menor money output
as
 select @precio_mayor=max(p.UnitPrice), @precio_menor=min(p.UnitPrice) 
 from categories c inner join Products p on c.CategorieID=p.CategoriesID
 where c.CategorieName like @categoria_name
go

/*Como hay variables definidas en el SP, y de salida en este caso, se deben declarar tambièn en la ejecución*/
declare @p money
declare @q money
exec spPrevioMayor_PrecioMenor 'Confections' /*Nombre de la categoria que se eligio pasar, variable de entrada*/, @p output, @q output /*precio mayor y precio menor respectivamente*/
select @p as PrecioMayor, @q as PrecioMenor /*al ejecutar el SP tengo que hacer un select sobre las variables de salida para que se muestren*/


/*Ejercicio 3
Muestra un reporte donde se obtenga nombre de cliente, monto de venta, cantidad de ordendes. variables can_orden, nom_cliente*/

create Procedure pReporte_Ventas
@cant_orden int,
@nombre_cliente varchar(30),
as
 select c.ContactName, sum(od.Quantity*od.UnitPrice*(1-Discount)) as "Monto Venta", count(o.OrderID) as "Cantidad ORdenes"
 from Custumer c
 inner join Orders o on c.CustomerID=o.CustomerID
 inner join [Order Details] od on od.OrderID = o.OrderID
 where c.ContactName like @nombre_cliente
 group by c.ContactName
 having count(o.OrderID) > @cant_orden /*having porque en el where da error el count*/
 order by 2 desc /*así es el orden, where, group by, having, order by*/
go

exec pReporte_Ventas @cant_orden=14, @nombre_cliente='%iz%'; /*se pasan los valores en la llamada al SP, no hay variables de salida como en el anterior, solo de entrada*/

/*Ejercicio 4
 Cual es la venta total de cada categoria pero devuelta en un sp de tabla en linea multisentencia
 Parametros de entrada son año de inicio y año de fin*/

 create Procedure pCategoria_VEntas
 @category int
 @y_inicio int
 @Y_final int
 as
  select c.CategorieID, sum(od.UnitPrice * od.Quantity*(1-Discount)) as  "Monto_Categoria" 
  from categories c inner join Products p on p.CategorieID = c.CategorieID
  inner join [Order Details] od on od.ProductID = p.ProductID inner join Orders o on o.OrderID = od.OrderID
  where year(o.OrderDate) betwen @y_inicio and @Y_final and (c.CategorieID=@category)
  group by c.CategorieID
 go

 exec pCategoria_VEntas @category=4, @y_inicio=1997, @Y_final=1998;

 /*Ejercicio 5
 Reporte en un procedimiento donde aparezcan paìs de envio, max cantidad de unidades y max cantidad de ordenes. Variables año y mes*/

 create Procedure pVentas_Pais
@mes int
@anio int
 as
select o.ShipCountry, max(od.Quantity) as "Maximo Unidades", count(o.OrderID) as "Ordenes" 
from Orders o inner join [Order Details] od on o.OrderID = od.OrderID 
where month(o.OrderDate) = @mes and year(o.OrderDate) = @anio
group by o.ShipCountry
 having max(od.Quantity) >= (select max(od1.Quantity) 
from Orders o1 inner join [Order Details] od1 on o1.OrderID = od1.OrderID 
where month(o1.OrderDate) = @mes and year(o1.OrderDate) = @anio)
 go

 exec pVentas_Pais @mes=4, @anio=1997


 /*TRIGGERS
 desencadena acciones que pueden controlar el comportamiento de las tablas*/
 