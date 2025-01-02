% SD Card Power Consumption Analysis

% Read data from Excel file with preserved variable names
opts = detectImportOptions('SDLowPowerLogs.xlsx');
opts.VariableNamingRule = 'preserve';
data_table = readtable('SDLowPowerLogs.xlsx', opts);

% Extract card names (excluding 'Empty')
cards = data_table.Card(2:end);

% Get the numeric columns only (excluding 'Card' and 'begin to write sleep?')
numeric_cols = varfun(@isnumeric, data_table, 'OutputFormat', 'uniform');
numeric_cols(1) = false;  % Exclude 'Card' column
data_cols = find(numeric_cols);

% Get the empty baseline values
empty = table2array(data_table(1, data_cols));

% Get the data for all other cards
data = table2array(data_table(2:end, data_cols));

% Convert to µA and calculate differences from empty baseline
data_ua = (data - empty) * 1000;

% Create plots for each analysis
phases = {'Card Insertion', 'Begin Statement', 'Write File', 'Closed File (Idle)', 'SD End'};

close all;
for i = 1:5
    % Sort data for this phase
    [sorted_data, sort_idx] = sort(data_ua(:,i));
    sorted_cards = cards(sort_idx);
    
    figure('Position', [100, 100, 1200, 600]);
    bar(sorted_data);
    title(sprintf('SD Card Power Consumption: %s', phases{i}));
    ylabel('Current (µA)');
    xlabel('SD Card');
    xticks(1:length(sorted_cards));
    xticklabels(sorted_cards);
    xtickangle(45);
    grid on;
    
    % Adjust layout to prevent label cutoff
    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4);
    ax.Position = [left bottom ax_width ax_height];
    
    % Save plot
    saveas(gcf, sprintf('sd_power_%d_%s.png', i, strrep(phases{i}, ' ', '_')));
    close(gcf);
end

%%
% Create heatmap with separate color scaling for each phase
% Sort cards alphabetically
close all;
[sorted_cards, sort_idx] = sort(cards);
sorted_data_ua = data_ua(sort_idx, :);

% Create figure for heatmaps
figure('Position', [100, 100, 800, 600]);

% Create a subplot for each phase
for i = 1:5
    subplot(5,1,i);
    imagesc(sorted_data_ua(:,i)');
    colormap(gca, "jet");
    
    % Add colorbar for this phase
    h = colorbar;
    ylabel(h, 'Current (µA)');
    
    % Set y-axis label
    ylabel(phases{i});
    
    % Only show x-axis labels on bottom subplot
    if i == 5
        xticks(1:length(sorted_cards));
        xticklabels(sorted_cards);
        xtickangle(45);
    else
        xticks([]);
    end
    
    % Remove y-ticks since we have phase label
    yticks([]);
    
    % Add title only to top subplot
    if i == 1
        title('SD Card Power Consumption by Phase');
    end
end

% Adjust layout for better spacing
set(gcf, 'Units', 'normalized');
set(gcf, 'Position', [0.1, 0.1, 0.8, 0.8]);

% Save heatmap
saveas(gcf, 'sd_power_heatmap.png');