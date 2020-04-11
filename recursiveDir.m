function d = recursiveDir(folder,ext)
d = dir(fullfile(folder,ext));
% loop through folders
extended = dir(fullfile(folder,'*'));
for n = 1:length(extended)
    if extended(n).isdir && ~startsWith(extended(n).name,".")
        d = [d; dir(fullfile(folder,extended(n).name,ext))];
    end
end
end