CREATE OR REPLACE FUNCTION n_l_1_99(_numero NUMERIC) RETURNS TEXT AS $BODY$
DECLARE
	resultado TEXT;
	tmpNumero TEXT;
	decenas NUMERIC;
	unidades NUMERIC;
	d1_29 VARCHAR[];	
	d30_90 VARCHAR[];
BEGIN			
		d1_29 = ARRAY[' UN',' DOS',' TRES',' CUATRO',' CINCO',' SEIS',' SIETE',' OCHO',' NUEVE',' DIEZ',' ONCE',' DOCE',' TRECE',' CATORCE',' QUINCE',
		' DIECISEIS',' DIECISIETE',' DIECIOCHO',' DIECINUEVE',' VEINTE',' VEINTIUN',' VEINTIDOS', ' VEINTITRES', ' VEINTICUATRO', ' VEINTICINCO',
		' VEINTISEIS',' VEINTISIETE',' VEINTIOCHO',' VEINTINUEVE'];
		d30_90 = ARRAY[' ',' ',' TREINTA',' CUARENTA',' CINCUENTA',' SESENTA',' SETENTA',' OCHENTA',' NOVENTA'];
		
		tmpNumero = lpad(_numero::text, 2, '0');
		decenas = substr(tmpNumero, 1, 1)::NUMERIC;
		unidades = substr(tmpNumero, 2, 1)::NUMERIC;
		
		IF _numero <= 29 THEN
			resultado = d1_29[_numero];
		ELSEIF _numero <= 99 THEN
			resultado = d30_90[decenas];
			IF unidades > 0 THEN
				resultado = resultado || ' Y' || d1_29[unidades];
			END IF;
		END IF;
		
		RETURN resultado;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
		
CREATE OR REPLACE FUNCTION n_l_3digitos(_numero NUMERIC) RETURNS TEXT AS $BODY$
DECLARE
	resultado TEXT;
	tmpNumero TEXT;
	centenas NUMERIC;
	decenas NUMERIC;
	unidades NUMERIC;
	decenasYUnidades NUMERIC;
	d100_900 VARCHAR[];
BEGIN
		d100_900 = ARRAY[' CIENTO',' DOCIENTOS',' TRECIENTOS',' CUATROCIENTOS',' QUINIENTOS',' SEISCIENTOS',' SETECIENTOS',' OCHOCIENTOS',' NOVECIENTOS'];
		
		tmpNumero = lpad(_numero::text, 3, '0');
		centenas = substr(tmpNumero, 1, 1)::NUMERIC;
		decenas = substr(tmpNumero, 2, 1)::NUMERIC;
		unidades = substr(tmpNumero, 3, 1)::NUMERIC;
		decenasYUnidades = (substr(tmpNumero, 2, 1) || substr(tmpNumero, 3, 1))::NUMERIC;
		
		IF _numero <= 99 THEN
			resultado = n_l_1_99(decenasYUnidades);
		ELSEIF centenas = 1 AND decenas = 0 AND unidades = 0 THEN
				resultado = ' CIEN';
		ELSEIF centenas > 1 AND decenas = 0 AND unidades = 0 THEN
				resultado = d100_900[centenas];
		ELSE
				resultado = d100_900[centenas];
				resultado = resultado || n_l_1_99(decenasYUnidades);
		END IF;
		
		RETURN resultado;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION numtolet_convertir(_numero NUMERIC) RETURNS TEXT AS $BODY$
DECLARE
	resultado TEXT;
	tmpNumero TEXT;
	grupo1 NUMERIC;
	grupo2 NUMERIC;
	grupo3 NUMERIC;
	grupo4 NUMERIC;
BEGIN
		resultado = '';
		tmpNumero = lpad(_numero::text, 12, '0');
		grupo1 = substr(tmpNumero, 1, 3)::numeric;
		grupo2 = substr(tmpNumero, 4, 3)::numeric;
		grupo3 = substr(tmpNumero, 7, 3)::numeric;
		grupo4 = substr(tmpNumero, 10, 3)::numeric;
		
		IF grupo1 <> 0 THEN
			resultado = resultado || n_l_3digitos(grupo1) || ' MIL';
			IF substr(resultado, 1, 7) = ' UN MIL' THEN
				resultado = substr(resultado, 5);
			END IF;
		END IF;
		
		IF grupo1 <> 0 AND grupo2 = 0 THEN
			resultado = resultado || ' MILLONES';
		ELSEIF grupo2 = 1 THEN
			resultado = resultado || ' UN MILLÓN';
		ELSEIF grupo2 > 1 THEN
			resultado = resultado || n_l_3digitos(grupo2) || ' MILLONES';
		END IF;
		
		IF grupo3 <> 0 THEN
			resultado = resultado || n_l_3digitos(grupo3) || ' MIL';
			IF grupo3 = 1 THEN
				resultado = substr(resultado, 5);
			END IF;
		END IF;
		
		IF grupo4 <> 0 THEN
			resultado = resultado || n_l_3digitos(grupo4);
		END IF;

		
		RETURN resultado;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
	
CREATE OR REPLACE FUNCTION convertir_numeros_a_letras(_numero NUMERIC) RETURNS TEXT AS $BODY$
DECLARE
	longitud INTEGER;
	numeroT TEXT;
	tmpN TEXT;
	tmpD TEXT;
	pos INTEGER;
	resultado TEXT;
	numero NUMERIC;
	decimales NUMERIC;
BEGIN
	IF _numero >= 1000000000000 THEN
		RETURN 'NUMERO MUY GRANDE';
	END IF;
		-- Obtenermos numero y decimal por aparte
		numeroT = (_numero::NUMERIC(20,2))::TEXT;
		pos = POSITION('.' IN numeroT);
		
		numero = (substr(numeroT, 1, pos -1));
		decimales = (substr(numeroT, pos + 1));
		
		tmpN = '';
		tmpD = '';
		
		IF numero = 1 THEN
			resultado = 'UN PESO';
		ELSE
			SELECT INTO tmpN numtolet_convertir(numero) || ' PESOS';
			resultado = tmpN;		
		END IF;
		
		IF decimales > 0 THEN
			IF decimales = 1 THEN
				resultado = resultado || ' UN CENTAVO';
			ELSE
				SELECT INTO tmpD numtolet_convertir(decimales);
				resultado = resultado || ' CON ' || tmpD || ' CENTAVOS';		
			END IF;
		END IF;
		
		RETURN resultado;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- llamada final
select convertir_numeros_a_letras(1325000.01)
