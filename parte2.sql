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

		PROCEDURE P_ALTERAR_TABLA(PTAB VARCHAR2, PCOL VARCHAR2, PTIPO VARCHAR, PLONG NUMBER  DEFAULT 1);

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
						AND (FECHA_HASTA BETWEEN TRUNC(R.CHECK_IN) AND TRUNC(R.CHECK_OUT))));
				TAB_HAB T_HABITACIONES;
				IDX NUMBER;
				NUMERO_INVALIDO EXCEPTION;
				ERROR_FECHA EXCEPTION;
				
			BEGIN
				IF PCAPACIDAD NOT IN(1,2,3) THEN
					RAISE NUMERO_INVALIDO;
				END IF;
				IF FECHA_HASTA < FECHA_DESDE THEN
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
		PROCEDURE P_ALTERAR_TABLA(PTAB VARCHAR2, PCOL VARCHAR2, PTIPO VARCHAR, PLONG NUMBER  DEFAULT 1)
		IS
		V_SENTENCIA VARCHAR2(10000);
	
	BEGIN
		V_SENTENCIA := 'ALTER TABLE '|| PTAB || ' ADD ( ' ||PCOL|| ' '||PTIPO;
		IF PTIPO IN ('DATE', 'CLOB', 'BLOB','FLOB') THEN
			V_SENTENCIA :=  V_SENTENCIA || ')';
		ELSE
			V_SENTENCIA :=  V_SENTENCIA || '( '|| PLONG||' ))';
		END IF;
			--DBMS_OUTPUT.PUT_LINE (RTRIM(V_SENTENCIA));
			EXECUTE IMMEDIATE V_SENTENCIA;
		EXCEPTION
			WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE (sqlERRM);	
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


El procedimiento P_FACTURAR emitirá automáticamente la facturación 
para todas las habitaciones cuya reserva vence en el día, a partir de la vista V_CARGOS_HUESPEDES.
La factura tendrá





CREATE OR REPLACE PROCEDURE P_FACTURAR
IS
BEGIN
END P_FACTURAR;

------------------------TRIGGER 1

CREATE OR REPLACE TRIGGER T_BIDU_CARGO_RESERVA
	AFTER INSERT OR UPDATE OR DELETE ON CARGO_RESERVA
	FOR EACH ROW
	DECLARE 
	PROCEDURE P_ACTUALIZAR_DETALLE (PID NUMBER DEFAULT NULL, PMONTO NUMBER DEFAULT NULL)
	IS
		BEGIN 
			UPDATE DETALLE_PAGO D SET MONTO = NVL(MONTO ,0) +  NVL(PMONTO ,0)
			WHERE D.COD_FACTURA = PID;
		END;
	fUNCTION ES_CONFIRMADO (PID NUMBER)  RETURN BOOLEAN
	IS
		V_ESTADO VARCHAR2(2);	
		BEGIN
			SELECT ESTADO INTO V_ESTADO FROM RESERVA r
			WHERE CODIGO = PID;
		IF V_ESTADO = 'C' THEN		
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;	
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
		WHEN OTHERS THEN
			RETURN FALSE;
		END;
	
	BEGIN		
		IF UPDATING OR DELETING THEN 
			IF ES_CONFIRMADO(:OLD.CODIGO_RESERVA) THEN
				IF :OLD.APLICAR_COBRO = 'S' THEN
				 	P_ACTUALIZAR_DETALLE(:OLD.CODIGO_FACTURA, (:OLD.PRECIO_UNITARIO * :OLD.CANTIDAD) * -1);
				 END IF;
			ELSE
				RAISE_APPLICATION_ERROR(-20009, 'SE DEBE CONFIRMAR LA RESERVA');
			END IF;
		END IF; 
		IF UPDATING OR INSERTING THEN
			IF ES_CONFIRMADO(:NEW.CODIGO_RESERVA) THEN
			 IF :NEW.APLICAR_COBRO = 'S' THEN
			 	P_ACTUALIZAR_DETALLE(:NEW.CODIGO_FACTURA, (:NEW.PRECIO_UNITARIO * :NEW.CANTIDAD));
			 END IF;
			ELSE
			 RAISE_APPLICATION_ERROR(-20005, 'SE DEBE CONFIRMAR LA RESERVA');
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(-20008, 'OCURRIO UN ERROR INESPERADO ' || SQLERRM);
	END;

	-----4-
	BEGIN
	PCK_HOTEL.P_ALTERAR_TABLA('HUESPED','DOCUMENTO','BLOB');
	END;

CREATE DIRECTORY mis_blobs AS 'C:\MIS_BLOBS'; 
