create table #lancamentoCotista(ID_COTISTA int, DATA_LANCAMENTO DATE ,VALOR_CREDITO numeric(10,2),VALOR_DEBITO numeric(10,2), OBS VARCHAR(500), ID_MOEDA_LANCAMENTO INT, ORIGEM VARCHAR(50), DESTINO VARCHAR(50), ID_DESPESA INT, FATURADO INT);
create table #temp(ID_COTISTA int, DATA_LANCAMENTO DATE ,VALOR_CREDITO numeric(10,2),VALOR_DEBITO numeric(10,2), OBS VARCHAR(500), ID_MOEDA_LANCAMENTO INT, ORIGEM VARCHAR(50), DESTINO VARCHAR(50), ID_DESPESA INT, FATURADO INT);
declare @qtde int = 0;
declare @validaCredito int = 0;
declare @idC int = 0;
declare @dtLancamento date = null;
declare @vlrCredito numeric(10,2) = 0;
declare @vlrDebito numeric(10,2) = 0;
declare @obs varchar(10) = 'Transporte';
declare @moeda int = 0;	 
declare @origem varchar(10) = '-';
declare @destino varchar(10) = '-';
declare @idDesp int = 0;
declare @faturado int = 0;
declare @cotAtual int = 0;


insert into #temp(ID_COTISTA, DATA_LANCAMENTO, VALOR_DEBITO, OBS, ID_MOEDA_LANCAMENTO, ORIGEM, DESTINO,ID_DESPESA, FATURADO)
select DISTINCT C.ID_COTISTA,D.DT_DESPESA, CD.VALOR_TOTAL,CONCAT(GD.NOME, ' - ', D.DESCRICAO) AS DESCRICAO_DEBITO, ID_MOEDA, CO.NOME, CID.NOME, D.ID_DESPESA, FATURADO  from TB_DESPESA AS D
INNER JOIN TB_COTISTA_DESPESA AS CD ON CD.ID_DESPESA = D.ID_DESPESA 
INNER JOIN TB_COTISTA AS C ON C.ID_COTISTA = CD.ID_COTISTA
INNER JOIN TB_GRUPO_DESPESA AS GD ON GD.ID_GRUPO_DESPESA = D.ID_GRUPO_DESPESA
LEFT JOIN TB_TRECHO	AS T ON T.ID_TRECHO = D.ID_TRECHO
LEFT JOIN TB_AEROPORTO AS AO ON T.ID_AEROPORTO_ORIGEM = AO.ID_AEROPORTO
LEFT JOIN TB_CIDADE	AS CO ON AO.ID_CIDADE = CO.ID_CIDADE
LEFT JOIN TB_AEROPORTO AS AD ON T.ID_AEROPORTO_DESTINO = AD.ID_AEROPORTO
LEFT JOIN TB_CIDADE	AS CID ON AD.ID_CIDADE = CID.ID_CIDADE
WHERE DT_DESPESA BETWEEN  '1900-01-01' AND '2100-01-01'
AND (C.ID_COTISTA in (0) OR '0' = 0)
AND (T.TRECHO_SEM_REEMBOLSO != 1 OR T.TRECHO_SEM_REEMBOLSO IS NULL)
AND (FATURADO != 1 OR FATURADO IS NULL)
AND (GD.ID_GRUPO_DESPESA not in (0))
ORDER BY DT_DESPESA

Select @qtde = (Select COUNT(*) as QTDE FROM #temp WHERE VALOR_DEBITO IS NULL);
WHILE (SELECT count(*) FROM  #temp WHERE VALOR_DEBITO IS NULL) <= @qtde  
	BEGIN
		UPDATE #temp SET VALOR_DEBITO = (SELECT top 1   VALOR FROM TB_DESPESA WHERE ID_DESPESA = (select top 1 ID_DESPESA from #temp where VALOR_DEBITO is null)) where ID_DESPESA = (select top 1 ID_DESPESA from #temp where VALOR_DEBITO is null);
        SET @qtde = @qtde - 1;
	END

	INSERT INTO #temp(ID_COTISTA, DATA_LANCAMENTO, VALOR_CREDITO, OBS, ID_MOEDA_LANCAMENTO)
		SELECT ID_COTISTA,DATA, VALOR, OBS, ID_MOEDA FROM TB_CREDITO_COTISTA
		WHERE DATA BETWEEN  '1900-01-01' AND '2100-01-01'
		AND (ID_COTISTA in (0) OR '0' = 0)
		ORDER BY DATA

	declare @cur_IdCotista			int;
	declare @cur_DtLancamento		date;
	declare @cur_VlrCredtio			numeric (10,2);
	declare @cur_ValorDebito	    numeric(10,2);
	declare @cur_Obs				varchar(max);
	declare @cur_IdMoeda			int;
	declare @cur_Origem				varchar(40);
	declare @cur_Destino			varchar(40);
	declare @cur_IdDespesa			int;
	declare @cur_Faturado			int;

	declare cursor_credito cursor for

	SELECT * FROM #temp ORDER BY ID_COTISTA, DATA_LANCAMENTO
	
	open cursor_credito 
							
	fetch next from cursor_credito	into @cur_IdCotista	,
										 @cur_DtLancamento,
										 @cur_VlrCredtio,	
										 @cur_ValorDebito,
										 @cur_Obs,
										 @cur_IdMoeda,
										 @cur_Origem,	
										 @cur_Destino,
										 @cur_IdDespesa,
										 @cur_Faturado		

	set @validaCredito = 1;

	insert into #lancamentoCotista(ID_COTISTA, DATA_LANCAMENTO, VALOR_CREDITO, VALOR_DEBITO, OBS, ID_MOEDA_LANCAMENTO, ORIGEM, DESTINO,ID_DESPESA, FATURADO)
	Select  (select top 1 ID_COTISTA from #temp), (select top 1 DATA_LANCAMENTO from #temp), 0, 0, 'Inicial', 0, '-', '-', 0, 0
	set @idC = (select top 1 ID_COTISTA from #temp);
	set @dtLancamento = (select top 1 DATA_LANCAMENTO from #temp);

	while @@FETCH_STATUS = 0
			begin 
				if(@validaCredito < 24)
					begin	
						if(@idC = @cur_IdCotista)
							begin
								insert into #lancamentoCotista(ID_COTISTA, DATA_LANCAMENTO, VALOR_CREDITO, VALOR_DEBITO, OBS, ID_MOEDA_LANCAMENTO, ORIGEM, DESTINO,ID_DESPESA, FATURADO)
									Select @cur_IdCotista,
											@cur_DtLancamento,
											@cur_VlrCredtio,	
											@cur_ValorDebito,
											@cur_Obs,
											@cur_IdMoeda,
											@cur_Origem,	
											@cur_Destino,
											@cur_IdDespesa,
											@cur_Faturado

									set @idC = @cur_IdCotista;	
									set @validaCredito = @validaCredito + 1;
									set @dtLancamento = @cur_DtLancamento;
							end
								else
							begin
								insert into #lancamentoCotista(ID_COTISTA, DATA_LANCAMENTO, VALOR_CREDITO, VALOR_DEBITO, OBS, ID_MOEDA_LANCAMENTO, ORIGEM, DESTINO,ID_DESPESA, FATURADO)
									Select @cur_IdCotista, 
											@dtLancamento, 
											@vlrCredito, 
											@vlrDebito, 
											@obs, 
											@moeda, 
											@origem,
											@destino, 
											@idDesp, 
											@faturado

									set @dtLancamento = @cur_DtLancamento;
									set @idC = @cur_IdCotista;
							end
					end
						else
					begin	

							insert into #lancamentoCotista(ID_COTISTA, DATA_LANCAMENTO, VALOR_CREDITO, VALOR_DEBITO, OBS, ID_MOEDA_LANCAMENTO, ORIGEM, DESTINO,ID_DESPESA, FATURADO)
								Select @idC, 
										@dtLancamento, 
										@vlrCredito, 
										@vlrDebito, 
										@obs, 
										@moeda, 
										@origem,
										@destino, 
										@idDesp, 
										@faturado
							
							insert into #lancamentoCotista(ID_COTISTA, DATA_LANCAMENTO, VALOR_CREDITO, VALOR_DEBITO, OBS, ID_MOEDA_LANCAMENTO, ORIGEM, DESTINO,ID_DESPESA, FATURADO)
									Select @cur_IdCotista,
											@cur_DtLancamento,
											@cur_VlrCredtio,	
											@cur_ValorDebito,
											@cur_Obs,
											@cur_IdMoeda,
											@cur_Origem,	
											@cur_Destino,
											@cur_IdDespesa,
											@cur_Faturado

								set @validaCredito = 2;							
						end	


				fetch next from cursor_credito	into @cur_IdCotista,
														@cur_DtLancamento,
														@cur_VlrCredtio,	
														@cur_ValorDebito,
														@cur_Obs,
														@cur_IdMoeda,
														@cur_Origem,	
														@cur_Destino,
														@cur_IdDespesa,
														@cur_Faturado

		end

		close cursor_credito
		deallocate cursor_credito

		SELECT * FROM #lancamentoCotista

		--select ID_COTISTA,sum(VALOR_CREDITO) CREDITO, sum(VALOR_DEBITO) DEBITO 
		--	from   #lancamentoCotista 
		--	where  DATA_LANCAMENTO BETWEEN  '||DT_INICIAL||' AND '||DT_FINAL||'
		--	group by ID_COTISTA 
		--	order by ID_COTISTA;			

		drop table #temp
		drop table #lancamentoCotista;
