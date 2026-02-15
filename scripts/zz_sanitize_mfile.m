function changed = zz_sanitize_mfile(filePath)
% zz_sanitize_mfile Remove BOM/non-ASCII noise from .m files.
% This helps when files were copied via chat tools and hidden characters slipped in.

changed = false;

if exist(filePath, 'file') ~= 2
    error('File not found: %s', filePath);
end

fid = fopen(filePath, 'r');
if fid < 0
    error('Cannot open file: %s', filePath);
end
bytes = fread(fid, Inf, '*uint8');
fclose(fid);

orig = bytes;

% Drop UTF-8 BOM if present.
if numel(bytes) >= 3 && bytes(1) == 239 && bytes(2) == 187 && bytes(3) == 191
    bytes = bytes(4:end);
end

% Keep printable ASCII + TAB/LF/CR.
keep = (bytes >= 32 & bytes <= 126) | bytes == 9 | bytes == 10 | bytes == 13;
bytes = bytes(keep);

if ~isequal(orig, bytes)
    fid = fopen(filePath, 'w');
    if fid < 0
        error('Cannot write file: %s', filePath);
    end
    fwrite(fid, bytes, 'uint8');
    fclose(fid);
    changed = true;
end
end
