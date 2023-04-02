--------RESOLVER-----
--1. Se necesita la cantidad de ventas realizadas, el producto más vendido y el monto total transaccionado por cada mes del 2022.
  
  --1.1	cantidad de ventas realizadas, el monto total transaccionado: 
	SELECT FORMAT(FECHA_ORDER,'yyyyMM') AS PERIODO , COUNT(DISTINCT(N_ORDER)) AS CANTIDA_VENTAS, SUM(VALOR_TOTAL) AS VALOR_TOTAL   
	FROM [meli].[ORDER]
	GROUP BY FORMAT(FECHA_ORDER,'yyyyMM') ORDER BY 1 
	--se hace unA agrupacion por periodo YYYYMM, se hace un conteo para las diferentes ordenes, se hace sumatoria del valor total 
	--se ordenamiento para la visalizacion

  --1.2	el producto más vendido (*):
	SELECT  FORMAT(FECHA_ORDER,'yyyyMM') AS PERIODO, NOMBRE_ITEM, COUNT(CODIGO_ITEM) AS CNT 
	FROM [meli].[ORDER]
	LEFT JOIN [meli].[ITEM] ON CODIGO_ITEM = CODIGO 
	GROUP BY FORMAT(FECHA_ORDER,'yyyyMM'), NOMBRE_ITEM ORDER BY 3 DESC 
	--se hace una agrupacion por periodo YYYYMM y nombre de item (se usa un left join a meli.ITEM por el codigo para disponer el nombre)
	--se hace conteo de los item para las ordenes por perido
	--se hace ordenamiento descentende para que los productos con mayor frecuencia se visualicen de primeros

--2. Se solicita si es posible poblar una tabla con el precio , mail de usuario , fecha de baja y estado de los Items a fin del día.

	INSERT INTO [meli].[HISTORICO_ITEM] ([CODIGO],[VALOR_UNIT],[ESTADO],[FECHA_BAJA],[MODIFICADO_POR],[LOAD_DATE])
	SELECT CODIGO,VALOR_UNIT,ESTADO,FECHA_BAJA,MODIFICADO_POR,GETDATE()-10 AS LOAD_DATE
	FROM [meli].[ITEM]
	--se genera una sentencia insert con los campos indicados mas un campo con la fecha de ejecucion de la carga de datos
	--esto deberia ser un Store Procedure, que ejecute en las madrugadas 

	--evolucion de precios vs tiempo:
	SELECT FORMAT(A.LOAD_DATE,'yyyyMM') AS PERIODO, B.NOMBRE_ITEM, A.ESTADO, AVG(A.VALOR_UNIT) AS VALOR_MEDIO
	FROM [meli].[HISTORICO_ITEM] A
	LEFT JOIN meli.ITEM B ON A.CODIGO = B.CODIGO
	WHERE A.CODIGO IN (4,6,11) 
	GROUP BY FORMAT(A.LOAD_DATE,'yyyyMM'), B.NOMBRE_ITEM, A.ESTADO ORDER BY 1,2,3
	--se hace una agrupacion por periodo YYYYMM y nombre de item (se usa un left join a meli.ITEM por el codigo para disponer el nombre)
	--se usa al funsion AVG para generea el valor medio por periodo, se incluyen registros de ejemplo
	--se hace ordenamiento para visualizacion

	--evolucion precios mes anterio vs actual, (*) falta crear la consulta por ITEM vs variacion del precio promedio
	--en desarrollo.....
	SELECT NOMBRE_ITEM, Q1.VALOR_MEDIO AS V1, Q2.VALOR_MEDIO AS V2, ((Q2.VALOR_MEDIO - Q1.VALOR_MEDIO)/Q1.VALOR_MEDIO*100)AS [%VAR] 
	FROM [meli].[ITEM] I
	LEFT JOIN (
		SELECT FORMAT(A.LOAD_DATE,'yyyyMM') AS PERIODO, A.CODIGO, AVG(A.VALOR_UNIT) AS VALOR_MEDIO
		FROM [meli].[HISTORICO_ITEM] A
		WHERE YEAR(A.LOAD_DATE) = YEAR(CONVERT(date, DATEADD(MONTH, -1, GETDATE())) ) AND MONTH(A.LOAD_DATE) = MONTH(CONVERT(date, DATEADD(MONTH, -1, GETDATE())) )
		GROUP BY FORMAT(A.LOAD_DATE,'yyyyMM') , A.CODIGO  
		) Q1 ON I.CODIGO = Q1.CODIGO
	LEFT JOIN (
		SELECT FORMAT(B.LOAD_DATE,'yyyyMM') AS PERIODO, B.CODIGO, AVG(B.VALOR_UNIT) AS VALOR_MEDIO
		FROM [meli].[HISTORICO_ITEM] B
		WHERE YEAR(B.LOAD_DATE) = YEAR(GETDATE()) AND MONTH(B.LOAD_DATE) = MONTH(GETDATE())
		GROUP BY FORMAT(B.LOAD_DATE,'yyyyMM'), B.CODIGO 
		) Q2 ON I.CODIGO = Q2.CODIGO

	WHERE I.CODIGO IN (4,6,11)
	ORDER BY I.NOMBRE_ITEM


--3 Cargar tabla categoria 2 sin duplidos
	--seleccionar el registo mas nuevo e insertarlo en tabla 
	INSERT INTO [meli].[CATEGORY_V2] ([ID],[CATEGORIA],[DESCRIPCION_CATEGORIA],[PATH],[CREADO_EL],[LASTUPDATE],[MODIFICADO_POR])
	SELECT A.ID, A.CATEGORIA, A.DESCRIPCION_CATEGORIA,A.[PATH], A.CREADO_EL, A.LASTUPDATE, A.MODIFICADO_POR
	FROM meli.CATEGORY A
	INNER JOIN (SELECT B.ID, MAX(B.LASTUPDATE) AS LASTUPDATE 
				FROM meli.CATEGORY B GROUP BY B.ID) Q1 --esta subconsulta retorma el ID mas actualizado
	ON A.ID = Q1.ID AND A.LASTUPDATE = Q1.LASTUPDATE; 
	
	--al cruzar la tabla base con la subconsulta se subsana lA duplicidad de registros 

	select * from [meli].[CATEGORY];
	select * from [meli].[CATEGORY_v2];