ALTER SESSION SET CONTAINER=XEPDB1;

alter session set "_ORACLE_SCRIPT"=true;


/*  creacion del Tablespace */
CREATE TABLESPACE BASEDATOSTP
LOGGING
DATAFILE '/opt/oracle/oradata/XE/XEPDB1/basedatosp.dbf'
SIZE 45M REUSE
AUTOEXTEND ON 
NEXT 22500 K MAXSIZE 135M;

ALTER SESSION SET CONTAINER=XEPDB1;

alter session set "_ORACLE_SCRIPT"=true;


create user BASETP identified by BASETP
    DEFAULT TABLESPACE BASEDATOSTP
    TEMPORARY TABLESPACE TEMP;
GRANT DBA TO BASETP WITH ADMIN OPTION;

conn BASETP@XEPDB1


/* -----------------------------CREACION DE TABLAS -----------------------------*/
/* -----------------------------CREACION DE TABLAS -----------------------------*/
CREATE TABLE RESERVA(
 CODIGO NUMBER (12) GENERATED ALWAYS AS IDENTITY 
 START WITH 1 
MINVALUE 1
MAXVALUE 99999999
INCREMENT BY 1 NOCACHE NOCYCLE
CONSTRAINT PK_RESERVA PRIMARY KEY,
FECHA_RESERVA DATE NOT NULL,
HUESPED_TITULAR NUMBER (10) NOT NULL,
MONTO_TOTAL NUMBER(10)NOT NULL,
SALDO_ABONAR NUMBER(10)NOT NULL,
CHECK_IN DATE NOT NULL,
CHECK_OUT DATE NOT NULL,
NUM_HABITACION NUMBER (5) NOT NULL,
ESTADO VARCHAR2(1) NOT NULL,
CODIGO_CANAL NUMBER(5) NOT NULL)
TABLESPACE BASEDATOSTP
STORAGE (INITIAL 639K );

CREATE TABLE CARGO_RESERVA(
CODIGO_CARGO NUMBER(10) GENERATED ALWAYS AS IDENTITY 
 START WITH 1 
MINVALUE 1
MAXVALUE 99999999
INCREMENT BY 1 NOCACHE NOCYCLE
CONSTRAINT PK_CARGO_RESERVA PRIMARY KEY,
CODIGO_RESERVA NUMBER (12) NOT NULL,
ID_PROD_SERV NUMBER (5) NOT NULL,
PRECIO_UNITARIO NUMBER(10) NOT NULL,
CANTIDAD NUMBER (5) NOT NULL,
APLICAR_COBRO VARCHAR2(1) DEFAULT 'S' NOT NULL,
CODIGO_FACTURA NUMBER(5))
TABLESPACE BASEDATOSTP
STORAGE (INITIAL 21569 K);

CREATE TABLE OCUPANTE (
CODIGO_OCUPANTE NUMBER(10) NOT NULL,
CODIGO_RESERVA NUMBER(12) NOT NULL,
FEC_HORA_ENTRADA DATE NOT NULL,
FEC_HORA_SALIDA DATE)
TABLESPACE BASEDATOSTP
STORAGE (INITIAL 328K);



/*--------------------------------CONSTRAINTS----------------------------------

+-----------------------------------------+
|                 RESERVA                 |
+-----------------------------------------+
| PK_RESERVA (CODIGO)                     |
| CANAL_RESERVA_RESERVA_FK (CODIGO_CANAL) |
| HABITACION_RESERVA_FK (NUM_HABITACION)  |
| HUESPUED_RESERVA_FK (HUESPED_TITULAR)   |
+-----------------------------------------+*/

alter table RESERVA
  add constraint CANAL_RESERVA_RESERVA_FK foreign key (CODIGO_CANAL)
  references CANAL_RESERVA (CODIGO);

 alter table RESERVA
  add constraint HABITACION_RESERVA_FK foreign key (NUM_HABITACION)
  references HABITACION (NUMERO);
 
 alter table RESERVA
  add constraint HUESPED_RESERVA_FK foreign key (HUESPED_TITULAR)
  references HUESPED (CODIGO);
 
 alter table RESERVA 
  add constraint CHKFECHA CHECK (CHECK_OUT > CHECK_IN);
  
 alter table RESERVA 
  add constraint CHKESTADO CHECK (ESTADO = 'P' OR 
                                (ESTADO = 'C' AND SALDO_ABONAR = 0.5 * MONTO_TOTAL)
  								OR (ESTADO = 'F' AND CHECK_OUT IS NOT NULL ) OR ESTADO = 'X');
 
  
/*-----------------------------------------------------------------------------
+-----------------------------------------------+
|                 CARGO_RESERVA                 |
+-----------------------------------------------+
| PK_CARGO_RESERVA (CODIGO_CARGO)               |
| FACTURA_CONSUMO_RESERVA_FK (CODIGO_FACTURA)   |
| PRODUCTO_SERVICIO_CONSUMO_R199 (ID_PROD_SERV) |
| RESERVA_CONSUMO_RESERVA_FK (CODIGO_RESERVA))  |
+-----------------------------------------------+*/

  
  alter table CARGO_RESERVA
    add constraint FACTURA_CONSUMO_RESERVA_FK foreign key (CODIGO_FACTURA)
    references FACTURA_VENTA (CODIGO);
 
  alter table CARGO_RESERVA
  add constraint PRODUCTO_SERVICIO_CONSUMO_R199 foreign key (ID_PROD_SERV)
  references PRODUCTO_SERVICIO (ID);
  
  alter table CARGO_RESERVA
    add constraint RESERVA_CONSUMO_RESERVA_FK foreign key (CODIGO_RESERVA)
    references RESERVA (CODIGO) ON DELETE CASCADE;
  
  alter table CARGO_RESERVA 
    add constraint CHK_APLICAR_COBRO CHECK ((APLICAR_COBRO = 'N' AND CODIGO_FACTURA IS NOT NULL) OR 
  										  APLICAR_COBRO = 'S');
  											
 
/*-----------------------------------------------------------------------------
 * 
+---------------------------------------------------+
|                     OCUPANTE                      |
+---------------------------------------------------+
| PK_COD_OCUPANTE (CODIGO_OCUPANTE, CODIGO_RESERVA) |
| HUESPUED_OCUPANTE_FK (CODIGO_OCUPANTE)            |
| RESERVA_OCUPANTE_FK (CODIGO_RESERVA)              |
+---------------------------------------------------+
 */ 
 
 alter table OCUPANTE
  add constraint HUESPED_OCUPANTE_FK foreign key (CODIGO_OCUPANTE)
  references HUESPED (CODIGO);
 
 alter table OCUPANTE
  add constraint RESERVA_OCUPANTE_FK foreign key (CODIGO_OCUPANTE)
  references RESERVA (CODIGO);
 
 alter table OCUPANTE
  add constraint PK_COD_OCUPANTE primary key (CODIGO_OCUPANTE, CODIGO_RESERVA);
 
  alter table OCUPANTE 
  add constraint CHK_FECHA_SALIDA CHECK (FEC_HORA_SALIDA > FEC_HORA_ENTRADA);
 
 
 
 /*-----------------------------------PARTE B--------------------------------*/
 
create sequence SEC_PAGO_ITEM
	increment by 1
	start with 1
	maxvalue 99999
	nocache
	nocycle;

---------------------------SENTENCIA SELECT - SUBQUERIES - SENTENCIA DML---------------------
---------------------------------------------3-----------------------------------------------
INSERT
	INTO
	DETALLE_PAGO (COD_FACTURA,
	NUM_ITEM,
	FORMA_PAGO,
	MONTO,
	MARCA_TARJETA,
	NUMERO_TARJETA,
	CODIGO_EMISOR)
VALUES ( (
SELECT
	FV.CODIGO cod_factura
FROM
	FACTURA_VENTA fv
JOIN HUESPED h ON
	FV.CODIGO_HUESPED = (
	SELECT
		CODIGO
	FROM
		HUESPED
	WHERE
		UPPER(PRIMER_NOMBRE)= UPPER('JUAN')
		AND UPPER(SEGUNDO_NOMBRE) = UPPER('RAMON')
		AND UPPER(PRIMER_APELLIDO) = UPPER('CESPEDES'))
JOIN RESERVA rv ON
	rv.HUESPED_TITULAR = (
	SELECT
		CODIGO
	FROM
		HUESPED
	WHERE
		UPPER(PRIMER_NOMBRE)= UPPER('JUAN')
		AND UPPER(SEGUNDO_NOMBRE) = UPPER('RAMON')
		AND UPPER(PRIMER_APELLIDO) = UPPER('CESPEDES'))
	AND TRUNC(FV.FECHA_EMISION)= TRUNC(SYSDATE)
	AND TRUNC(rv.CHECK_OUT) = TRUNC(SYSDATE)),
SEC_PAGO_ITEM.NEXTVAL,
'EF',
(
SELECT
	SUM(PRECIO_UNITARIO*CANTIDAD) monto
FROM
	CARGO_RESERVA
WHERE
	CODIGO_FACTURA = (
	SELECT
		FV.CODIGO cod_factura
	FROM
		FACTURA_VENTA fv
	JOIN HUESPED h ON
		FV.CODIGO_HUESPED = (
		SELECT
			CODIGO
		FROM
			HUESPED
		WHERE
			UPPER(PRIMER_NOMBRE)= UPPER('JUAN')
			AND UPPER(SEGUNDO_NOMBRE) = UPPER('RAMON')
			AND UPPER(PRIMER_APELLIDO) = UPPER('CESPEDES'))
	JOIN RESERVA rv ON
		rv.HUESPED_TITULAR = (
		SELECT
			CODIGO
		FROM
			HUESPED
		WHERE
			UPPER(PRIMER_NOMBRE)= UPPER('JUAN')
			AND UPPER(SEGUNDO_NOMBRE) = UPPER('RAMON')
			AND UPPER(PRIMER_APELLIDO) = UPPER('CESPEDES')
      )
		AND TRUNC(FV.FECHA_EMISION)= TRUNC(SYSDATE)
		AND TRUNC(rv.CHECK_OUT) = TRUNC(SYSDATE))),
NULL,
NULL,
NULL )


----------------------------------------------6-----------------------------------------------
CREATE ROLE PRUEBA_2;
SPOOL otorgar_permisos.sql
SELECT 'GRANT SELECT,INSERT, DELETE, UPDATE ON "' || OBJ.object_name || '" TO PRUEBA_2;'
FROM   USER_OBJECTS OBJ
WHERE  OBJ.object_type = 'TABLE'
AND NOT EXISTS (SELECT '1'
                   FROM all_tab_privs PRIV
                   WHERE PRIV.grantee = 'PRUEBA_2'
                   AND PRIV.privilege NOT IN('SELECT', 'INSERT','DELETE','UPDATE')
                   AND PRIV.table_name = OBJ.object_name);
SPOOL OFF


--@otorgar_permisos.sql
--PARA VER LOS PRIVILEGIOS
--SELECT * FROM ROLE_TAB_PRIVS WHERE ROLE = 'PRUEBA_2';
  
  