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

% Convert to mA for first 3 plots, µA for last 2
data_ma = data - empty;
data_ua = data_ma * 1000;

% Create plots for each analysis
phases = {'Card Insertion', 'Begin Statement', 'Write File', 'Closed File (Idle)', 'SD End'};

close all;
for i = 1:5
    % Sort data for this phase
    if i <= 3
        [sorted_data, sort_idx] = sort(data_ma(:,i));
        current_unit = 'mA';
    else
        [sorted_data, sort_idx] = sort(data_ua(:,i));
        current_unit = 'µA';
    end
    sorted_cards = cards(sort_idx);
    
    figure('Position', [100, 100, 1200, 800]);  % Larger figure
    bar(sorted_data);
    title(sprintf('SD Card Power Consumption: %s', phases{i}), 'FontSize', 16);
    ylabel(sprintf('Current (%s)', current_unit), 'FontSize', 14);
    xlabel('SD Card', 'FontSize', 14);
    xticks(1:length(sorted_cards));
    xticklabels(sorted_cards);
    xtickangle(45);
    grid on;
    
    % Adjust layout to prevent label cutoff
    ax = gca;
    ax.FontSize = 12;  % Larger tick labels
    
    % Set margins with more padding
    left_margin = 0.1;     % Slightly less left margin
    bottom_margin = 0.28;  % Even more bottom margin for x-labels
    right_margin = 0.05;   % Small right margin
    top_margin = 0.1;      % Keep top margin
    
    ax.Position = [left_margin bottom_margin ...
                  1-left_margin-right_margin ...
                  1-bottom_margin-top_margin];
    
    % Save plot
    saveas(gcf, sprintf('sd_power_%d_%s.png', i, strrep(phases{i}, ' ', '_')));
    close(gcf);
end

%%
% Create heatmap
% Sort cards by Closed File (Idle) values (4th column)
[~, sort_idx] = sort(data_ua(:,4));  % Sort by Closed File values
sorted_cards = cards(sort_idx);
sorted_data_ua = data_ua(sort_idx, :);

% Create figure with landscape orientation and extra space for colorbar and labels
figure('Position', [100, 100, 1400, 900]);  % Made taller

% Create logarithmic heatmap
% Add small offset to handle zeros/negative values
offset = abs(min(sorted_data_ua(:))) + 1;
log_data = log10(sorted_data_ua + offset)';

% Set up axes with room for colorbar and labels
ax = axes;
ax.Position = [0.15 0.2 0.65 0.7];  % Increased left margin, adjusted width to compensate

% Plot heatmap
imagesc(log_data);
colormap(jet);
h = colorbar;
h.Position(1) = 0.85;  % Move colorbar to the right

% Create custom colorbar tick labels that show actual values
ticks = get(h, 'Ticks');
tick_values = 10.^ticks - offset;
tick_labels = arrayfun(@(x) sprintf('%.0f', x), tick_values, 'UniformOutput', false);
set(h, 'TickLabels', tick_labels);
ylabel(h, 'Current (µA, log scale)', 'FontSize', 14);

% Increase font sizes
set(gca, 'FontSize', 14);

% Set and rotate x-axis labels
xticks(1:length(sorted_cards));
xticklabels(sorted_cards);
xtickangle(45);

% Set y-axis labels
yticks(1:length(phases));
yticklabels(phases);

% Add title
title('SD Card Power Consumption Heat Map', 'FontSize', 16);
xlabel('SD Card', 'FontSize', 14);
ylabel('Analysis Phase', 'FontSize', 14);

% Make sure aspect ratio creates square cells
pbaspect([length(sorted_cards) length(phases) 1]);

% Save heatmap in high resolution
print('sd_power_heatmap', '-dpng', '-r300');
close(gcf);

%%
% Output Closed File (Idle) currents in sorted order (relative to Empty baseline)
idle_currents = data_ua(:,4);  % Column 4 is testFile.close()
[sorted_idle_currents, sort_idx] = sort(idle_currents);
sorted_idle_cards = cards(sort_idx);

% Create formatted output string
output_str = '';
for i = 1:length(sorted_idle_cards)
    output_str = sprintf('%s%s - %.0fµA\n', output_str, sorted_idle_cards{i}, sorted_idle_currents(i));
end

% Display the list
fprintf('\nClosed File (Idle) Currents (relative to Empty baseline, sorted):\n%s', output_str);

%%
% Create scatter plot of Write File vs Closed File currents
figure('Position', [100, 100, 1200, 800]);  % Larger figure for better visibility

% Get Write File and Closed File currents
write_currents = data_ua(:,3);
closed_currents = data_ua(:,4);

% Create color map for points (one color per card)
colors = jet(length(cards));

% Define different markers for better differentiation
markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};  % circle, square, diamond, triangle up/down/left/right, pentagon, hexagon

% Create axes with proper margins
ax = axes;
% Set margins with more padding and better balance
left_margin = 0.12;    % Keep left margin
bottom_margin = 0.15;  % Keep bottom margin
right_margin = 0.35;   % Even more right margin for larger legend text
top_margin = 0.1;      % Keep top margin

ax.Position = [left_margin bottom_margin ...
              1-left_margin-right_margin ...
              1-bottom_margin-top_margin];

% Plot each point individually with different colors and markers
hold on;
for i = 1:length(cards)
    marker_idx = mod(i-1, length(markers)) + 1;  % Cycle through markers if more cards than markers
    scatter(write_currents(i), closed_currents(i), 200, colors(i,:), markers{marker_idx}, 'filled', ...
        'DisplayName', cards{i}, 'LineWidth', 1.5);
end

% Add linear fit
p = polyfit(write_currents, closed_currents, 1);
x_fit = linspace(min(write_currents), max(write_currents), 100);
y_fit = polyval(p, x_fit);
plot(x_fit, y_fit, 'w--', 'LineWidth', 2, 'DisplayName', 'Linear Fit');

% Add labels and title
xlabel('Write File Current (µA)', 'FontSize', 14);
ylabel('Closed File (Idle) Current (µA)', 'FontSize', 14);
title('Write File vs. Closed File Current Consumption', 'FontSize', 16);

% Add grid
grid on;

% Adjust font size
set(gca, 'FontSize', 14);

% Add R² value and p-value
R = corrcoef(write_currents, closed_currents);
R2 = R(1,2)^2;
n = length(write_currents);
t = R(1,2) * sqrt((n-2)/(1-R(1,2)^2));  % t-statistic
p = 2 * (1 - tcdf(abs(t), n-2));         % two-tailed p-value

% Position text with more right spacing
text(max(write_currents) - 0.05 * range(write_currents), max(closed_currents), ...
    sprintf('R² = %.3f\np = %.3f', R2, p), ...
    'FontSize', 14, 'Color', 'white', 'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'right');

% Add legend outside plot area with better positioning
legend('Location', 'eastoutside', 'FontSize', 14);  % Increased font size
legend_obj = legend;
legend_obj.Position(1) = 1 - right_margin + 0.02; % Adjust legend position

% Save plot
print('write_vs_closed_scatter', '-dpng', '-r300');
close(gcf);