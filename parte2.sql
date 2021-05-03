/* El tipo de dato T_HABITACIONES como una tabla indexada que tendrá los atributos:
	o CATEGORIA VARCHAR2(100)
	o COSTO_X_NOCHE NUMBER(10)
La función F_VERIFICAR_DISPONIBILIDAD que recibirá como parámetros la capacidad
como un valor numérico, fecha_desde y fecha_hasta; y devolverá una variable del tipo T_HABITACIONES.
*/

--INSTANCIA: CON_TP pruebas: BASEPRUEBA


CREATE  OR REPLACE PACKAGE PCK_HOTEL-- SE CREA EL PAQUETE
	IS
		TYPE CAMPOS_HABITACIONES IS RECORD ( --CREAMOS UN TIPO DE DATO CAMPOS_HABITACION
		CATEGORIA VARCHAR2(100),
		COSTO_X_NOCHE NUMBER(10));
		TYPE T_HABITACIONES IS TABLE OF CAMPOS_HABITACIONES INDEX BY BINARY_INTEGER; --SE CREA UNA TABLA INDEXADA T_HABITACIONES DE TIPOS CAMPOS_HABITACIONES

		FUNCTION F_VERIFICAR_DISPONIBILIDAD (PCAPACIDAD NUMBER, FECHA_DESDE DATE, FECHA_HASTA DATE) RETURN T_HABITACIONES;
		
		--PROCEDURE P_FACTURAR;

		--PROCEDURE ALTERAR_TABLE(NOMBRE_TABLA VARCHAR2(15), TIPO_DATO VARCHAR2, LONGITUD NUMBER);

END PCK_HOTEL;

CREATE OR REPLACE PACKAGE BODY PCK_HOTEL
	IS
		FUNCTION F_VERIFICAR_DISPONIBILIDAD (PCAPACIDAD NUMBER, FECHA_DESDE DATE, FECHA_HASTA DATE) RETURN T_HABITACIONES
			IS				
				CURSOR HABITACIONES_DISPONIBLES IS
					SELECT H.NUMERO, C.DESCRIPCION, C.COSTO_X_NOCHE FROM HABITACION H
					JOIN CATEGORIA C
					ON H.COD_CATEGORIA = C.CODIGO
					WHERE C.CAPACIDAD_MAXIMA = PCAPACIDAD
					AND H.NUMERO NOT IN (
						SELECT R.NUM_HABITACION FROM RESERVA R
						WHERE TRUNC(R.CHECK_OUT) != FECHA_DESDE
						OR ((FECHA_DESDE BETWEEN TRUNC(R.CHECK_IN) AND TRUNC(R.CHECK_OUT))
						AND (FECHA_HASTA BETWEEN TRUNC(R.CHECK_IN) AND TRUNC(R.CHECK_OUT)))
						);
				TAB_HAB T_HABITACIONES;
				IDX NUMBER;
				NUMERO_INVALIDO EXCEPTION;
				ERROR_FECHA EXCEPTION;				
			BEGIN
				IF PCAPACIDAD NOT IN(1,2,3) THEN
					RAISE NUMERO_INVALIDO;
				END IF;
				IF FECHA_HASTA<FECHA_DESDE THEN
					RAISE ERROR_FECHA;
				END IF;				
				FOR HAB IN HABITACIONES_DISPONIBLES LOOP
					TAB_HAB(HAB.NUMERO).CATEGORIA := HAB.DESCRIPCION;
					TAB_HAB(HAB.NUMERO).COSTO_X_NOCHE:=HAB.COSTO_X_NOCHE;
				END LOOP;
			RETURN TAB_HAB;
					
			EXCEPTION
				WHEN NUMERO_INVALIDO THEN
					DBMS_OUTPUT.PUT_LINE ('CANTIDAD NO VALIDA');
				WHEN ERROR_FECHA THEN
					DBMS_OUTPUT.PUT_LINE ('FECHAS NO VALIDAS');
				WHEN OTHERS THEN
					DBMS_OUTPUT.PUT_LINE ('OCURRIO UN ERROR EN LA EJECUCION DE LA FUNCION ' || SQLERRM);	
			END;
END;

/*-------PL PARA PRUEBA DE LA FUNCION--------*/
DECLARE
RST PCK_HOTEL.T_HABITACIONES;
IND BINARY_INTEGER;
BEGIN
	RST:= PCK_HOTEL.F_VERIFICAR_DISPONIBILIDAD(2,TO_DATE('2021-08-18','YYYY-MM-DD'),TO_DATE('2021-08-28','YYYY-MM-DD'));
	IND := RST.FIRST;
	WHILE IND <= RST.LAST LOOP
		DBMS_OUTPUT.PUT_LINE ('NRO HABITACION: '|| IND || ' CATEGORIA: '|| RST(IND).CATEGORIA || ' PRECIO X NOCHE: '|| RST(IND).COSTO_X_NOCHE);
		IND:= RST.NEXT(IND);
	END LOOP;
END;
/*------------------------------------------*/


/*El procedimiento P_FACTURAR emitirá automáticamente la facturación 
para todas las habitaciones cuya reserva vence en el día, a partir de la vista V_CARGOS_HUESPEDES.*/


CREATE O REPLACE P_FACTURAR IS
BEGIN
	INSERT INTO FACTURAR_VENTA(CODIGO,FECHA_EMISION,FECHA_CARGA,NUMERO_FACTURA,
	NUMERO_TIMBRADO,MONTO_GRAVADO,MONTO_IVA,MONTO_EXENTO,CODIGO_HUESPED)
	VALUES(MAX(CODIGO)+1),SYSDATE,SYSDATE,
	SELECT MAX(TIM.ULTIMO_NUM_EMITIDO)+1 FROM TIMBRADO TIM
	WHERE TIM.VALIDO_HASTA >= TRUNC(SYSDATE),
	/*NUMERO_TIMBRADO*/,
	/*MONTO_GRAVADO*/,
	/*MONTO_IVA*/,
	/*MONTO_EXENTO*/
	
	/*ME FALTAN AGREGAR COSAS A LA FUNCION*/
	/*todavia no entiendo bien estos ultimos para meter en el insert*/
	
	,
	CODIGO_HUESPED
END;

/*TRIGGERS*/

/*TRIGGERS
 * ESTABAMOS VIENDO CON LUIS, ES EL EJERCICIO QUE HIZO PERO CREO QUE TIENE ALGUNOS ERRORES
 * POR SI SIRVA xd
 *     */
CREATE OR REPLACE TRIGGER TR_SUMA_RESERVA BEFORE INSERT OR UPDATE OR DELETE ON CARGO_RESERVA FOR EACH ROW
	DECLARE
		
	BEGIN
	
		IF INSERTING THEN
			IF :NEW.APLICAR_COBRO == 'S' THEN
				UPDATE RESERVA SET MONTO_TOTAL = NVL(MONTO_TOTAL, 0) + (:NEW.PRECIO_UNITARIO * :NEW.CANTIDAD)
					WHERE RESERVA.CODIGO = :NEW.CODIGO_RESERVA;
			END IF;
		
		ELSIF DELETING THEN
			IF :OLD.APLICAR_COBRO == 'S' THEN
				UPDATE RESERVA SET MONTO_TOTAL = :OLD.MONTO_TOTAL - (PRECIO_UNITARIO * CANTIDAD)
					WHERE RESERVA.CODIGO = :NEW.CODIGO_RESERVA;
			END IF;
		
		ELSIF UPDATING THEN
			IF :NEW.APLICAR_COBRO == 'S' THEN
				UPDATE RESERVA SET MONTO_TOTAL = (:OLD.MONTO_TOTAL - (:OLD.PRECIO_UNITARIO * :OLD.CANTIDAD))
					 + (:NEW.PRECIO_UNITARIO * :NEW.CANTIDAD)
					WHERE RESERVA.CODIGO = :NEW.CODIGO_RESERVA;
			END IF;
		END IF;
		
	END TR_SUMA_RESERVA;


/*OBJETOS*/
/*a) Cree el tipo T_OCUPANTE como un objeto con los siguientes elementos:*/
CREATE OR REPLACE TYPE T_OCUPANTE IS OBJECT 
(
	TIPO_DOCUMENTO VARCHAR2(100),
	NUM_DOCUMENTO VARCHAR2(100), 
	NOMBRE VARCHAR2(100), 
	APELLIDO VARCHAR2(100)
);

/*b)	El tipo tabla TAB_OCUPANTES del TIPO T_OCUPANTE*/
CREATE TABLE TAB_OCUPANTES OF T_OCUPANTE;

/*c) Cree el tipo T_HABITACIÓN como un objeto con los siguientes elementos */
CREATE OR REPLACE TYPE T_HABITACION AS OBJECT(
	NRO_HABITACION NUMBER(5),-- ESTOY TANTANDO LOS VALORES PARA EL TAMAÑO
	OCUPANTES TAB_OCUPANTES
);
