#!/bin/bash

# Bitcoin Data Plotter - Price Only Version
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQL_CMD="/mnt/c/xampp/mysql/bin/mysql.exe"
DB_HOST="127.0.0.1"
DB_USER="root"
DB_NAME="crypto_tracker"

# Function to export price data for plotting
export_price_data() {
    echo "Exporting Bitcoin price data for plotting..."
    
    # Export to CSV (price only)
    $MYSQL_CMD -h $DB_HOST -u $DB_USER -e "USE $DB_NAME; SELECT last_updated, price_usd FROM bitcoin_prices ORDER BY last_updated;" > bitcoin_data.csv
    
    echo "Data exported to bitcoin_data.csv"
    echo "First 5 records:"
    head -5 bitcoin_data.csv
    echo "Total records: $(wc -l < bitcoin_data.csv)"
}

# Function to show basic statistics
show_stats() {
    echo "Bitcoin Price Statistics:"
    $MYSQL_CMD -h $DB_HOST -u $DB_USER -e "USE $DB_NAME; SELECT COUNT(*) as total_records, MIN(price_usd) as min_price, MAX(price_usd) as max_price, AVG(price_usd) as avg_price, MIN(last_updated) as first_record, MAX(last_updated) as last_record FROM bitcoin_prices;"
}

# Function to show price differences with percentage changes
price_difference() {
    echo "Bitcoin Price Differences (Last 10 records):"
    echo "Date       | Price      | Change %"
    echo "----------------------------------"
    
    # Get data and store in array
    data=()
    while IFS= read -r line; do
        date_part=$(echo "$line" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' | head -1)
        numeric_price=$(echo "$line" | grep -o '[0-9]*\.[0-9]*' | head -1)
        if [ -n "$date_part" ] && [ -n "$numeric_price" ]; then
            data+=("$date_part $numeric_price")
        fi
    done < <($MYSQL_CMD -h $DB_HOST -u $DB_USER -e "USE $DB_NAME; SELECT DATE(last_updated), ROUND(price_usd, 2) FROM bitcoin_prices ORDER BY last_updated DESC LIMIT 10;" --batch --skip-column-names)
    
    # Process differences with awk for calculation
    for i in "${!data[@]}"; do
        IFS=' ' read -r date price <<< "${data[$i]}"
        
        if [ $i -eq 0 ]; then
            printf "%-10s | $%-9s | FIRST\n" "$date" "$price"
        else
            # Get previous price
            prev_price=$(echo "${data[$((i-1))]}" | awk '{print $2}')
            
            # Calculate percentage change using awk
            change_pct=$(awk -v current="$price" -v previous="$prev_price" 'BEGIN {
                if (previous != 0) {
                    change = ((current - previous) / previous) * 100
                    printf "%.2f", change
                } else {
                    print "0.00"
                }
            }')
            
            # Format output
            if [ "$change_pct" = "0.00" ]; then
                printf "%-10s | $%-9s | 0.00%%\n" "$date" "$price"
            elif [ "$(echo "$change_pct" | cut -c1)" = "-" ]; then
                printf "%-10s | $%-9s | %s%%\n" "$date" "$price" "$change_pct"
            else
                printf "%-10s | $%-9s | +%s%%\n" "$date" "$price" "$change_pct"
            fi
        fi
    done
}

# Function to show daily summary
daily_summary() {
    echo "Daily Price Summary:"
    $MYSQL_CMD -h $DB_HOST -u $DB_USER -e "USE $DB_NAME; SELECT DATE(last_updated) as date, COUNT(*) as records, ROUND(MIN(price_usd), 2) as min_price, ROUND(MAX(price_usd), 2) as max_price, ROUND(AVG(price_usd), 2) as avg_price FROM bitcoin_prices GROUP BY DATE(last_updated) ORDER BY DATE(last_updated) DESC LIMIT 7;"
}

# Main function
main() {
    case "$1" in
        "export")
            export_price_data
            ;;
        "stats")
            show_stats
            ;;
        "difference")
            price_difference
            ;;
        "daily")
            daily_summary
            ;;
        "all")
            echo "=== Bitcoin Price Data Analysis ==="
            show_stats
            echo ""
            price_difference
            echo ""
            daily_summary
            ;;
        *)
            echo "Usage: ./plotter.sh [export|stats|difference|daily|all]"
            echo "  export     - Export price data to CSV"
            echo "  stats      - Show basic statistics"
            echo "  difference - Show price differences with % change"
            echo "  daily      - Show daily summary"
            echo "  all        - Run all analysis functions"
            ;;
    esac
}

main "$@"
