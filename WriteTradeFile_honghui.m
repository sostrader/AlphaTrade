function WriteTradeFile_honghui(AccountInfo, id)
global fid_log
numOfAccount = length(AccountInfo);
for ai = 1:numOfAccount
    if str2double(AccountInfo{ai}.ID) == id
        break;
    end
end

%% log
[idate, itime] = GetDateTimeNum();
fprintf(fid_log, '--->>> %s_%s,\tBegin write trade file. account = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME);

N_PART = str2double(AccountInfo{ai}.NPART);% 要写成N_PART个篮子文件，在xml中设置
path_account = [AccountInfo{ai}.BASEPATH AccountInfo{ai}.NAME '\'];

file_trade = [path_account 'trade_holding.txt'];
file_modle = [AccountInfo{ai}.BASEPATH 'com_data\modle.xlsx'];

%% write into trade files for client
if exist(file_trade, 'file')
    diffHolding = load(file_trade);
else
    fprintf(fid_log, '--->>> %s_%s,\tError not exist trade file. file = %s.\n', num2str(idate), num2str(itime), file_trade);
    fprintf(2, '--->>> %s_%s,\tError not exist trade file. file = %s.\n', num2str(idate), num2str(itime), file_trade);
    return;
end   
diffHolding(all(diffHolding(:,2) == 0,2), :) = [];

% devide into N_PART
numOfTrade = size(diffHolding,1);
one = ones(numOfTrade, numOfTrade);

dev_vol = floor(abs(diffHolding(:,2)) / 100 / N_PART);
rem_vol = rem(floor(abs(diffHolding(:,2) / 100)), N_PART);

dev_vol = diag(dev_vol);
dev_vol = (one * dev_vol)';
dev_vol(:,N_PART+1:end) = [];

rem_vol = diag(rem_vol);
rem_vol = (one * rem_vol)';
rem_vol(:, N_PART+1:end) = [];
tmp = 1:N_PART;
tmp = repmat(tmp, numOfTrade, 1);
tmp(:, N_PART+1:end) = [];
rem_vol = ((rem_vol - tmp) >= 0);

bs = abs(diffHolding(:,2)) ./ diffHolding(:,2);
bs = diag(bs);
bs = (one * bs)';
bs(:,N_PART+1:end) = [];

child_vol = (dev_vol + rem_vol) .* bs * 100; % 乘以100后变成股数, 并且带有符号

% begin to write in parts
Title = {'Market','Ticker','BS','Vol','Price','PriceType','DeltaPrice'};
[idate, itime] = GetDateTimeNum();
fprintf('--->>> %s_%s,\tTotal Part = %d. account = %s\n', num2str(idate), num2str(itime), N_PART, AccountInfo{ai}.NAME);
for ipart = 1:N_PART
	[idate, itime] = GetDateTimeNum();
	fprintf('--->>> %s_%s,\tGenerate Part %d.\n', num2str(idate), num2str(itime), ipart);
	fprintf(fid_log, '--->>> %s_%s,\tGenerate Part %d.\n', num2str(idate), num2str(itime), ipart);
	
	sfile_name = ['trade_sell_p' num2str(ipart)];% sell file
	bfile_name = ['trade_buy_p' num2str(ipart)];% buy file
	sfile_today = [path_account sfile_name '.xlsx'];
	bfile_today = [path_account bfile_name '.xlsx'];
    if exist(sfile_today, 'file')
		delete(sfile_today);
    end
    if exist(bfile_today, 'file')
		delete(bfile_today);
    end

    tmpVol = child_vol(:,ipart);
    tmpTicker = diffHolding(:,1);
    tmpTicker(all(tmpVol == 0, 2), :) = [];
    tmpVol(all(tmpVol == 0, 2), :) = [];	

    sTicker = tmpTicker(tmpVol < 0, 1);
    sVol = abs(tmpVol(tmpVol < 0, 1));
    bTicker = tmpTicker(tmpVol > 0, 1);
    bVol = tmpVol(tmpVol > 0, 1);

    if copyfile(file_modle, sfile_today,'f') == 1
        if xlswrite(sfile_today,sTicker,'SHEET1','A1') == 1
        else
            fprintf('sTicker FAILED.\n');
        end
        if xlswrite(sfile_today, sVol, 'SHEET1', 'C1') == 1
        else
            fprintf('sVol Failed.\n');
        end

        [idate, itime] = GetDateTimeNum();
        fprintf(fid_log, '--->>> %s_%s,\tDone write trade file. file = %s.\n', num2str(idate), num2str(itime), sfile_today);
        dst_sfile_today = [path_account 'HistoricalTrade\' sfile_name '_' num2str(idate) '_' num2str(itime) '.xlsx'];
        CopyFile2HistoryDir(sfile_today, dst_sfile_today);
    else
        [idate, itime] = GetDateTimeNum();
        fprintf(2, '--->>> %s_%s,\tError when copy modle file, when generate trade file. account = %s, file = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME, file_modle);
        fprintf(fid_log, '--->>> %s_%s,\tError when copy modle file, when generate trade file. account = %s, file = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME, file_modle);
    end

    if copyfile(file_modle, bfile_today,'f') == 1
        if xlswrite(bfile_today,bTicker,'SHEET1','A1') == 1
        else
            fprintf('bTicker FAILED.\n');
        end
        if xlswrite(bfile_today, bVol, 'SHEET1', 'C1') == 1
        else
            fprintf('bVol Failed.\n');
        end

        [idate, itime] = GetDateTimeNum();
        fprintf(fid_log, '--->>> %s_%s,\tDone write trade file. file = %s.\n', num2str(idate), num2str(itime), bfile_today);
        dst_bfile_today = [path_account 'HistoricalTrade\' bfile_name '_' num2str(idate) '_' num2str(itime) '.xlsx'];
        CopyFile2HistoryDir(bfile_today, dst_bfile_today);
    else
        [idate, itime] = GetDateTimeNum();
        fprintf(2, '--->>> %s_%s,\tError when copy modle file, when generate trade file. account = %s, file = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME, file_modle);
        fprintf(fid_log, '--->>> %s_%s,\tError when copy modle file, when generate trade file. account = %s, file = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME, file_modle);
    end
end
    
[idate, itime] = GetDateTimeNum();
fprintf(fid_log, '--->>> %s_%s,\tEnd generate trade vol. account = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME);
fprintf('--->>> %s_%s,\tEnd generate trade vol. account = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME);
