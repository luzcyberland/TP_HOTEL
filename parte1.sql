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
  references RESERVA (CODIGO);
  
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

 
 
 
  
  
  