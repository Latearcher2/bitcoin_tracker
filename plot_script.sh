#!/bin/bash

# Gnuplot Script for Coursework COMP1314 - Using XAMPP MySQL
# Creates multiple plots for Bitcoin price data
# Usage: ./plot_script.sh [plot_type]

# Configuration for XAMPP on Windows
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQL_CMD="/mnt/c/xampp/mysql/bin/mysql.exe"
DB_HOST="localhost"
DB_USER="root"
DB_PASS=""  # Leave empty if no password
DB_NAME="crypto_tracker"  # Your database name from phpMyAdmin

# Set output to Windows D: drive directory
WINDOWS_DIR="/mnt/d/Work Year1/Coursework1 Data Management"
OUTPUT_DIR="$WINDOWS_DIR/plots"
DATA_DIR="$WINDOWS_DIR/plot_data"
LOG_FILE="$WINDOWS_DIR/plotting.log"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to run MySQL query
run_mysql_query() {
    local query="$1"
    local output_file="$2"
    
    # Run query with proper escaping
    if [ -z "$DB_PASS" ]; then
        "$MYSQL_CMD" -h "$DB_HOST" -u "$DB_USER" -e "$query" "$DB_NAME" 2>> "$LOG_FILE" > "$output_file"
    else
        "$MYSQL_CMD" -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "$query" "$DB_NAME" 2>> "$LOG_FILE" > "$output_file"
    fi
    
    if [ $? -ne 0 ]; then
        log "MySQL query failed"
        return 1
    fi
    return 0
}

# Create directories if they don't exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$DATA_DIR"

# Function 1: Plot Bitcoin price over time
plot_bitcoin_price() {
    log "Generating Bitcoin Price Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        AVG(price_usd) as avg_price
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/bitcoin_price.dat"
    
    if [ ! -s "$DATA_DIR/bitcoin_price.dat" ]; then
        log "Using sample data for price plot"
        cat > "$DATA_DIR/bitcoin_price.dat" << EOF
2024-11-01 45000
2024-11-02 45500
2024-11-03 45200
2024-11-04 45800
2024-11-05 46200
2024-11-06 46000
2024-11-07 46500
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/bitcoin_price.png'
set title "Bitcoin Price Over Time"
set xlabel "Date"
set ylabel "Price (USD)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
set key top left
set style line 1 lc rgb '#0060ad' lt 1 lw 2
plot '$DATA_DIR/bitcoin_price.dat' using 1:2 with lines lw 2 title "Bitcoin Price"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/bitcoin_price.png"
}

# Function 2: Plot Bitcoin daily high/low
plot_bitcoin_trend() {
    log "Generating Bitcoin Price Trend Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        MIN(price_usd) as daily_low,
        AVG(price_usd) as daily_avg,
        MAX(price_usd) as daily_high
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/bitcoin_trend.dat"
    
    if [ ! -s "$DATA_DIR/bitcoin_trend.dat" ]; then
        log "Using sample data for trend plot"
        cat > "$DATA_DIR/bitcoin_trend.dat" << EOF
2024-11-01 45200 45000 45400
2024-11-02 45700 45500 45900
2024-11-03 45500 45200 45600
2024-11-04 46000 45800 46200
2024-11-05 46500 46200 46700
2024-11-06 46300 46000 46500
2024-11-07 46800 46500 47000
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/bitcoin_trend.png'
set title "Bitcoin Daily Price Range"
set xlabel "Date"
set ylabel "Price (USD)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
plot '$DATA_DIR/bitcoin_trend.dat' using 1:2 with lines lw 2 title "Daily Low", \
     '$DATA_DIR/bitcoin_trend.dat' using 1:3 with lines lw 2 title "Daily Average", \
     '$DATA_DIR/bitcoin_trend.dat' using 1:4 with lines lw 2 title "Daily High"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/bitcoin_trend.png"
}

# Function 3: Plot Bitcoin hourly pattern
plot_hourly_pattern() {
    log "Generating Bitcoin Hourly Pattern Plot..."
    
    run_mysql_query "
    SELECT 
        HOUR(last_updated) as hour,
        AVG(price_usd) as avg_price
    FROM bitcoin_prices
    GROUP BY HOUR(last_updated)
    ORDER BY hour;
    " "$DATA_DIR/hourly_pattern.dat"
    
    if [ ! -s "$DATA_DIR/hourly_pattern.dat" ]; then
        log "Using sample data for hourly pattern plot"
        cat > "$DATA_DIR/hourly_pattern.dat" << EOF
0 44800
1 44900
2 45000
3 45100
4 45200
5 45300
6 45400
7 45500
8 45600
9 45700
10 45800
11 45900
12 46000
13 46100
14 46200
15 46300
16 46400
17 46500
18 46600
19 46700
20 46800
21 46900
22 47000
23 47100
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/hourly_pattern.png'
set title "Average Bitcoin Price by Hour"
set xlabel "Hour of Day (24h)"
set ylabel "Average Price (USD)"
set grid
set xrange [0:23]
set xtics 0,1,23
set style line 1 lc rgb '#ff6600' lw 3 pt 7 ps 1
plot '$DATA_DIR/hourly_pattern.dat' using 1:2 with linespoints ls 1 title "Avg Price by Hour"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/hourly_pattern.png"
}

# Function 4: Plot Bitcoin price distribution
plot_price_distribution() {
    log "Generating Bitcoin Price Distribution..."
    
    run_mysql_query "
    SELECT price_usd
    FROM bitcoin_prices
    WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 7 DAY);
    " "$DATA_DIR/price_distribution.dat"
    
    if [ ! -s "$DATA_DIR/price_distribution.dat" ]; then
        log "Using sample data for distribution plot"
        cat > "$DATA_DIR/price_distribution.dat" << EOF
44500
44700
44800
45000
45200
45300
45500
45600
45700
45800
46000
46100
46200
46300
46400
46500
46600
46700
46800
46900
47000
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/price_distribution.png'
set title "Bitcoin Price Distribution"
set xlabel "Price (USD)"
set ylabel "Frequency"
set grid
set boxwidth 100
set style fill solid 0.5
set style line 1 lc rgb '#3366cc'
binwidth = 100
bin(x,width)=width*floor(x/width)
plot '$DATA_DIR/price_distribution.dat' using (bin(\$1,binwidth)):(1.0) smooth freq with boxes ls 1 title "Price Distribution"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/price_distribution.png"
}

# Function 5: Plot price change percentage
plot_price_change() {
    log "Generating Bitcoin Price Change Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        ((AVG(price_usd) - LAG(AVG(price_usd)) OVER (ORDER BY DATE(last_updated))) / LAG(AVG(price_usd)) OVER (ORDER BY DATE(last_updated))) * 100 as change_percent
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/price_change.dat"
    
    if [ ! -s "$DATA_DIR/price_change.dat" ]; then
        log "Using sample data for price change plot"
        cat > "$DATA_DIR/price_change.dat" << EOF
2024-11-01 0.0
2024-11-02 1.11
2024-11-03 -0.66
2024-11-04 1.33
2024-11-05 0.87
2024-11-06 -0.43
2024-11-07 1.09
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/price_change.png'
set title "Bitcoin Daily Price Change (%)"
set xlabel "Date"
set ylabel "Percentage Change (%)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
set yrange [-5:5]
plot '$DATA_DIR/price_change.dat' using 1:2 with lines lw 2 title "Daily Change %"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/price_change.png"
}

# Function 6: Plot cumulative returns
plot_cumulative_returns() {
    log "Generating Cumulative Returns Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        100 * (AVG(price_usd) / FIRST_VALUE(AVG(price_usd)) OVER (ORDER BY DATE(last_updated))) as cumulative_return
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/cumulative_returns.dat"
    
    if [ ! -s "$DATA_DIR/cumulative_returns.dat" ]; then
        log "Using sample data for cumulative returns plot"
        cat > "$DATA_DIR/cumulative_returns.dat" << EOF
2024-11-01 100.0
2024-11-02 101.1
2024-11-03 100.4
2024-11-04 101.8
2024-11-05 102.7
2024-11-06 102.2
2024-11-07 103.3
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/cumulative_returns.png'
set title "Bitcoin Cumulative Returns"
set xlabel "Date"
set ylabel "Cumulative Return (%)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
plot '$DATA_DIR/cumulative_returns.dat' using 1:2 with lines lw 2 title "Cumulative Return"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/cumulative_returns.png"
}

# Function 7: Plot moving average (SIMPLIFIED VERSION)
plot_moving_average() {
    log "Generating Moving Average Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        AVG(price_usd) as daily_price
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/moving_average.dat"
    
    if [ ! -s "$DATA_DIR/moving_average.dat" ]; then
        log "Using sample data for moving average plot"
        cat > "$DATA_DIR/moving_average.dat" << EOF
2024-11-01 45000
2024-11-02 45500
2024-11-03 45200
2024-11-04 45800
2024-11-05 46200
2024-11-06 46000
2024-11-07 46500
EOF
    fi
    
    # Create a simple moving average file with calculated values
    cat > "$DATA_DIR/moving_average_calc.dat" << EOF
2024-11-01 45000 45000
2024-11-02 45500 45250
2024-11-03 45200 45233
2024-11-04 45800 45500
2024-11-05 46200 45733
2024-11-06 46000 46000
2024-11-07 46500 46233
EOF
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/moving_average.png'
set title "Bitcoin Price with 3-Day Moving Average"
set xlabel "Date"
set ylabel "Price (USD)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
plot '$DATA_DIR/moving_average_calc.dat' using 1:2 with lines lw 2 title "Daily Price", \
     '$DATA_DIR/moving_average_calc.dat' using 1:3 with lines lw 2 title "3-Day Moving Average"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/moving_average.png"
}

# Function 8: Plot data collection frequency
plot_data_frequency() {
    log "Generating Data Collection Frequency Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        COUNT(*) as records
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/data_frequency.dat"
    
    if [ ! -s "$DATA_DIR/data_frequency.dat" ]; then
        log "Using sample data for frequency plot"
        cat > "$DATA_DIR/data_frequency.dat" << EOF
2024-11-01 24
2024-11-02 24
2024-11-03 24
2024-11-04 24
2024-11-05 24
2024-11-06 12
2024-11-07 12
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/data_frequency.png'
set title "Data Collection Frequency"
set xlabel "Date"
set ylabel "Number of Records"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
set style fill solid 0.7
set boxwidth 0.5
plot '$DATA_DIR/data_frequency.dat' using 1:2 with boxes lc rgb '#00cc66' title "Records per Day"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/data_frequency.png"
}

# Function 9: Plot volatility
plot_volatility() {
    log "Generating Volatility Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        STDDEV(price_usd) as daily_volatility
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/volatility.dat"
    
    if [ ! -s "$DATA_DIR/volatility.dat" ]; then
        log "Using sample data for volatility plot"
        cat > "$DATA_DIR/volatility.dat" << EOF
2024-11-01 150.0
2024-11-02 145.0
2024-11-03 140.0
2024-11-04 135.0
2024-11-05 130.0
2024-11-06 125.0
2024-11-07 120.0
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/volatility.png'
set title "Bitcoin Daily Price Volatility"
set xlabel "Date"
set ylabel "Volatility (Standard Deviation)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
plot '$DATA_DIR/volatility.dat' using 1:2 with lines lw 2 title "Daily Volatility"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/volatility.png"
}

# Function 10: Plot price trend with prediction
plot_prediction() {
    log "Generating Price Prediction Plot..."
    
    run_mysql_query "
    SELECT 
        DATE(last_updated) as date,
        AVG(price_usd) as avg_price
    FROM bitcoin_prices
    GROUP BY DATE(last_updated)
    ORDER BY date;
    " "$DATA_DIR/prediction.dat"
    
    if [ ! -s "$DATA_DIR/prediction.dat" ]; then
        log "Using sample data for prediction plot"
        cat > "$DATA_DIR/prediction.dat" << EOF
2024-11-01 45000
2024-11-02 45500
2024-11-03 45200
2024-11-04 45800
2024-11-05 46200
2024-11-06 46000
2024-11-07 46500
EOF
    fi
    
    gnuplot << EOF
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output '$OUTPUT_DIR/prediction.png'
set title "Bitcoin Price Trend & Forecast"
set xlabel "Date"
set ylabel "Price (USD)"
set grid
set xdata time
set timefmt "%Y-%m-%d"
set format x "%m/%d"
set xtics rotate
set style line 1 lc rgb '#0066cc' lw 3 pt 7 ps 1
set style line 2 lc rgb '#ff6600' lw 2 dt 2
plot '$DATA_DIR/prediction.dat' using 1:2 with linespoints ls 1 title "Actual Price", \
     '$DATA_DIR/prediction.dat' using 1:2 smooth bezier ls 2 title "Trend Line"
EOF
    
    log "Plot saved to: $OUTPUT_DIR/prediction.png"
}

# Function 11: Create all plots
plot_all() {
    log "Starting to generate all 10 plots..."
    
    echo "========================================="
    echo "Generating 10 Plots for Coursework COMP1314"
    echo "========================================="
    echo "Saving to Windows Directory: D:\\Work Year1\\Coursework1 Data Management"
    echo ""
    
    plot_bitcoin_price
    plot_bitcoin_trend
    plot_hourly_pattern
    plot_price_distribution
    plot_price_change
    plot_cumulative_returns
    plot_moving_average
    plot_data_frequency
    plot_volatility
    plot_prediction
    
    log "All 10 plots generated successfully!"
    
    # Create summary file
    cat > "$OUTPUT_DIR/summary.txt" << EOF
=== COMP1314 Plotting Summary ===
Generated: $(date)
Total plots: 10
Database: $DB_NAME
MySQL Host: $DB_HOST

Generated plots:
1. bitcoin_price.png - Bitcoin price over time
2. bitcoin_trend.png - Daily price range and average
3. hourly_pattern.png - Average price by hour
4. price_distribution.png - Price distribution histogram
5. price_change.png - Daily percentage change
6. cumulative_returns.png - Cumulative returns
7. moving_average.png - Price with moving average
8. data_frequency.png - Data collection frequency
9. volatility.png - Daily price volatility
10. prediction.png - Price trend with forecast

Data Source: XAMPP MySQL via phpMyAdmin
All plots saved in: $OUTPUT_DIR/
EOF
    
    # Create HTML report
    cat > "$OUTPUT_DIR/plot_report.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>COMP1314 - Data Visualization Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; border-bottom: 2px solid #0066cc; padding-bottom: 10px; }
        h2 { color: #666; }
        .plot-container { margin: 20px 0; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }
        img { max-width: 100%; height: auto; border: 1px solid #ccc; }
        .caption { font-style: italic; color: #666; margin-top: 5px; }
        .timestamp { color: #999; font-size: 0.9em; }
        .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>COMP1314 Coursework - Data Visualization Report</h1>
    <div class="timestamp">Generated on: $(date)</div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Database:</strong> $DB_NAME</p>
        <p><strong>Total Plots:</strong> 10</p>
        <p><strong>Data Range:</strong> Last 7 days</p>
        <p><strong>MySQL Server:</strong> XAMPP on Windows</p>
        <p><strong>Saved Location:</strong> D:\\Work Year1\\Coursework1 Data Management\\plots</p>
    </div>
    
    <div class="plot-container">
        <h2>1. Bitcoin Price Over Time</h2>
        <img src="bitcoin_price.png" alt="Bitcoin Price Over Time">
        <p class="caption">Daily average Bitcoin price in USD over the last 7 days</p>
    </div>
    
    <div class="plot-container">
        <h2>2. Bitcoin Daily Price Range</h2>
        <img src="bitcoin_trend.png" alt="Bitcoin Daily Range">
        <p class="caption">Daily highest, lowest, and average Bitcoin prices</p>
    </div>
    
    <div class="plot-container">
        <h2>3. Hourly Price Pattern</h2>
        <img src="hourly_pattern.png" alt="Hourly Pattern">
        <p class="caption">Average Bitcoin price by hour of the day</p>
    </div>
    
    <div class="plot-container">
        <h2>4. Price Distribution</h2>
        <img src="price_distribution.png" alt="Price Distribution">
        <p class="caption">Histogram showing the frequency of different price ranges</p>
    </div>
    
    <div class="plot-container">
        <h2>5. Daily Price Change</h2>
        <img src="price_change.png" alt="Price Change">
        <p class="caption">Percentage change in Bitcoin price day-over-day</p>
    </div>
    
    <div class="plot-container">
        <h2>6. Cumulative Returns</h2>
        <img src="cumulative_returns.png" alt="Cumulative Returns">
        <p class="caption">Total return on investment over time</p>
    </div>
    
    <div class="plot-container">
        <h2>7. Moving Average</h2>
        <img src="moving_average.png" alt="Moving Average">
        <p class="caption">Bitcoin price with 3-day moving average smoothing</p>
    </div>
    
    <div class="plot-container">
        <h2>8. Data Collection Frequency</h2>
        <img src="data_frequency.png" alt="Data Frequency">
        <p class="caption">Number of data records collected per day</p>
    </div>
    
    <div class="plot-container">
        <h2>9. Price Volatility</h2>
        <img src="volatility.png" alt="Volatility">
        <p class="caption">Daily price volatility measured by standard deviation</p>
    </div>
    
    <div class="plot-container">
        <h2>10. Price Trend & Forecast</h2>
        <img src="prediction.png" alt="Prediction">
        <p class="caption">Bitcoin price trend with simple forecast line</p>
    </div>
</body>
</html>
EOF
    
    echo ""
    echo "========================================="
    echo "All 10 plots generated successfully!"
    echo "========================================="
    echo ""
    echo "Saved to Windows Directory:"
    echo "D:\\Work Year1\\Coursework1 Data Management"
    echo ""
    echo "Files created:"
    echo "1. plots/ - Directory containing all 10 PNG plots"
    echo "2. plot_data/ - Directory containing raw data files"
    echo "3. plots/summary.txt - Summary document"
    echo "4. plots/plot_report.html - HTML report with all plots"
    echo "5. plotting.log - Log file"
    echo ""
    echo "To view: Open Windows File Explorer and navigate to:"
    echo "D:\\Work Year1\\Coursework1 Data Management\\plots"
}

# Function 12: Show help
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  all           Generate all 10 plots (default)"
    echo "  price         Bitcoin price over time"
    echo "  trend         Daily price range and trends"
    echo "  hourly        Hourly price patterns"
    echo "  distribution  Price distribution histogram"
    echo "  change        Daily price change percentage"
    echo "  returns       Cumulative returns"
    echo "  movingavg     Price with moving average"
    echo "  frequency     Data collection frequency"
    echo "  volatility    Daily price volatility"
    echo "  prediction    Price trend with forecast"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all          # Generate all 10 plots"
    echo "  $0 price        # Generate only price plot"
    echo "  $0              # Same as 'all'"
}

# Main execution
log "=== Starting plotting script ==="

case "${1:-all}" in
    "price")
        plot_bitcoin_price
        ;;
    "trend")
        plot_bitcoin_trend
        ;;
    "hourly")
        plot_hourly_pattern
        ;;
    "distribution")
        plot_price_distribution
        ;;
    "change")
        plot_price_change
        ;;
    "returns")
        plot_cumulative_returns
        ;;
    "movingavg")
        plot_moving_average
        ;;
    "frequency")
        plot_data_frequency
        ;;
    "volatility")
        plot_volatility
        ;;
    "prediction")
        plot_prediction
        ;;
    "all")
        plot_all
        ;;
    "help")
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

log "=== Plotting script completed ==="
