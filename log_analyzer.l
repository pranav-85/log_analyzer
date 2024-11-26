%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#define MAX_ENTRIES 1000
#define MAX_FILTERS 10

typedef struct {
    char timestamp[30];
    char date[11];    // YYYY-MM-DD
    char time[9];     // HH:MM:SS
    char level[10];
    char message[256];
} LogEntry;

typedef struct {
    char type[20];     // "date" or "time" or "level"
    char op[3];        // "=", ">=", "<="
    char value[30];
    int or_group;
} FilterCondition;

typedef struct {
    int year;
    int month;
    int day;
} ParsedDate;

LogEntry log_entries[MAX_ENTRIES];
int log_count = 0;

// New filter structure
FilterCondition filters[MAX_FILTERS];
int filter_count = 0;

// Command type for stats
char command_type[20] = "";
char command_value[30] = "";

void add_log_entry(const char *timestamp, const char *level, const char *message) {
    if (log_count < MAX_ENTRIES) {
        strncpy(log_entries[log_count].timestamp, timestamp, 29);
        log_entries[log_count].timestamp[29] = '\0';
        
        strncpy(log_entries[log_count].date, timestamp, 10);
        log_entries[log_count].date[10] = '\0';
        
        strncpy(log_entries[log_count].time, timestamp + 11, 8);
        log_entries[log_count].time[8] = '\0';
        
        strncpy(log_entries[log_count].level, level, 9);
        log_entries[log_count].level[9] = '\0';
        strncpy(log_entries[log_count].message, message, 255);
        log_entries[log_count].message[255] = '\0';
        
        log_count++;
    } else {
        fprintf(stderr, "Log entry limit reached! Ignoring more entries.\n");
    }
}

// Helper function to compare dates
int compare_dates(const char *date1, const char *date2) {
    return strcmp(date1, date2);
}

// Helper function to compare times
int compare_times(const char *time1, const char *time2) {
    return strcmp(time1, time2);
}

// Function to parse date string into ParsedDate structure
ParsedDate parse_date(const char *date_str) {
    ParsedDate date = {0, 0, 0};
    sscanf(date_str, "%d-%d-%d", &date.year, &date.month, &date.day);
    return date;
}

// Function to compare two dates
int compare_dates_advanced(const char *date1_str, const char *date2_str) {
    ParsedDate date1 = parse_date(date1_str);
    ParsedDate date2 = parse_date(date2_str);
    
    // Compare year
    if (date1.year != date2.year) {
        return date1.year - date2.year;
    }
    
    // Compare month if years are equal
    if (date1.month != date2.month) {
        return date1.month - date2.month;
    }
    
    // Compare day if years and months are equal
    return date1.day - date2.day;
}

// Function to check if a single filter condition matches
int matches_condition(LogEntry *entry, FilterCondition *condition) {
    if (strcmp(condition->type, "date") == 0) {
        int cmp = compare_dates_advanced(entry->date, condition->value);
        if (strcmp(condition->op, "=") == 0) return cmp == 0;
        if (strcmp(condition->op, ">=") == 0) return cmp >= 0;
        if (strcmp(condition->op, "<=") == 0) return cmp <= 0;
    }
    else if (strcmp(condition->type, "time") == 0) {
        int cmp = compare_times(entry->time, condition->value);
        if (strcmp(condition->op, "=") == 0) return cmp == 0;
        if (strcmp(condition->op, ">=") == 0) return cmp >= 0;
        if (strcmp(condition->op, "<=") == 0) return cmp <= 0;
    }
    else if (strcmp(condition->type, "level") == 0) {
        return (strcmp(entry->level, condition->value) == 0);
    }
    
    return 1;  // Default to true if filter type unknown
}


int matches_filter(LogEntry *entry) {
    if (filter_count == 0) {
        return 1;  // No filters applied
    }
    
    int current_or_group = filters[0].or_group;
    int or_group_match = 0;
    
    for (int i = 0; i < filter_count; i++) {
        // If we're starting a new OR group, check if previous group matched
        if (filters[i].or_group != current_or_group) {
            if (!or_group_match) {
                return 0;  // Previous OR group didn't match
            }
            current_or_group = filters[i].or_group;
            or_group_match = 0;
        }
        
        // Check if current condition matches
        if (matches_condition(entry, &filters[i])) {
            or_group_match = 1;
        }
    }
    
    // Check final OR group
    return or_group_match;
}

void print_log_statistics() {
    int error_count = 0, info_count = 0, warning_count = 0, debug_count = 0;
    
    for (int i = 0; i < log_count; i++) {
        if (strcmp(log_entries[i].level, "ERROR") == 0) error_count++;
        else if (strcmp(log_entries[i].level, "INFO") == 0) info_count++;
        else if (strcmp(log_entries[i].level, "WARNING") == 0) warning_count++;
        else if (strcmp(log_entries[i].level, "DEBUG") == 0) debug_count++;
    }

    printf("\nOverall Log Statistics:\n");
    printf("=====================\n");
    printf("ERROR:   %d\n", error_count);
    printf("INFO:    %d\n", info_count);
    printf("WARNING: %d\n", warning_count);
    printf("DEBUG:   %d\n", debug_count);
    printf("Total:   %d\n", log_count);
}

void print_daily_statistics(const char *date) {
    int error_count = 0, info_count = 0, warning_count = 0, debug_count = 0;
    int total_count = 0;
    
    for (int i = 0; i < log_count; i++) {
        if (strcmp(log_entries[i].date, date) == 0) {
            if (strcmp(log_entries[i].level, "ERROR") == 0) error_count++;
            else if (strcmp(log_entries[i].level, "INFO") == 0) info_count++;
            else if (strcmp(log_entries[i].level, "WARNING") == 0) warning_count++;
            else if (strcmp(log_entries[i].level, "DEBUG") == 0) debug_count++;
            total_count++;
        }
    }

    printf("\nLog Statistics for %s:\n", date);
    printf("=====================%.*s\n", (int)strlen(date), "=================");
    printf("ERROR:   %d\n", error_count);
    printf("INFO:    %d\n", info_count);
    printf("WARNING: %d\n", warning_count);
    printf("DEBUG:   %d\n", debug_count);
    printf("Total:   %d\n", total_count);
}

void print_filtered_logs() {
    if (filter_count == 0) {
        return;
    }

    printf("\nFiltered Log Entries (");
    int current_or_group = filters[0].or_group;
    
    for (int i = 0; i < filter_count; i++) {
        if (filters[i].or_group != current_or_group) {
            printf(") AND (");
            current_or_group = filters[i].or_group;
        } else if (i > 0) {
            printf(" OR ");
        }
        printf("%s%s'%s'", 
               filters[i].type,
               filters[i].op,
               filters[i].value);
    }
    printf("):\n");
    printf("==========================================\n");
    
    // Rest of the function remains the same...
    int filtered_count = 0;
    for (int i = 0; i < log_count; i++) {
        if (matches_filter(&log_entries[i])) {
            printf("[%s] %s: %s\n", 
                   log_entries[i].timestamp, 
                   log_entries[i].level, 
                   log_entries[i].message);
            filtered_count++;
        }
    }
    printf("\nShowing %d matching entries\n", filtered_count);
}

// Function to add a new filter condition
void add_filter_condition(const char *type, const char *op, const char *value, int or_group) {
    if (filter_count < MAX_FILTERS) {
        strncpy(filters[filter_count].type, type, sizeof(filters[filter_count].type) - 1);
        strncpy(filters[filter_count].op, op, sizeof(filters[filter_count].op) - 1);
        strncpy(filters[filter_count].value, value, sizeof(filters[filter_count].value) - 1);
        filters[filter_count].or_group = or_group;
        filter_count++;
    }
}


// Add this function after the print_filtered_logs() function
void write_logs_to_csv(const char* filename) {
    FILE *csv_file = fopen(filename, "w");
    if (!csv_file) {
        fprintf(stderr, "Error creating CSV file: %s\n", filename);
        return;
    }
    
    // Write CSV header
    fprintf(csv_file, "Timestamp,Level,Message\n");
    
    // Write entries that match the filter (or all entries if no filter)
    for (int i = 0; i < log_count; i++) {
        if (matches_filter(&log_entries[i])) {
            // Escape any commas in the message with quotes
            if (strchr(log_entries[i].message, ',') != NULL) {
                fprintf(csv_file, "%s,%s,\"%s\"\n",
                       log_entries[i].timestamp,
                       log_entries[i].level,
                       log_entries[i].message);
            } else {
                fprintf(csv_file, "%s,%s,%s\n",
                       log_entries[i].timestamp,
                       log_entries[i].level,
                       log_entries[i].message);
            }
        }
    }
    
    fclose(csv_file);
    printf("\nData exported to %s\n", filename);
}

%}

%%
"["[0-9][0-9][0-9][0-9]"-"[0-9][0-9]"-"[0-9][0-9]" "[0-9][0-9]":"[0-9][0-9]":"[0-9][0-9]"]"[ ]    {
    yymore();
}

("ERROR"|"INFO"|"WARNING"|"DEBUG")":"[ ]    {
    yymore();
}

[^\n]*\n    {
    char *log_text = strdup(yytext);
    char timestamp[30] = {0};
    char level[10] = {0};
    char message[256] = {0};
    
    strncpy(timestamp, log_text + 1, 19);
    
    char *level_start = strstr(log_text, "] ") + 2;
    char *level_end = strstr(level_start, ":");
    strncpy(level, level_start, level_end - level_start);
    
    char *msg_start = level_end + 2;
    strncpy(message, msg_start, strlen(msg_start) - 1);
    
    add_log_entry(timestamp, level, message);
    free(log_text);
}

.    ; /* Ignore any other characters */

%%

// Modify the print_usage function to add the CSV export option
void print_usage(const char* program_name) {
    printf("Usage: %s <logfile> [command [filter_expression]] [into \"output.csv\"]\n\n", program_name);
    printf("Commands:\n");
    printf("  filter \"<expression>\"  Filter entries by specified criteria\n");
    printf("  stats date          Show statistics for specific date\n");
    printf("  into \"file.csv\"    Export results to CSV file\n\n");
    printf("Filter expressions:\n");
    printf("  \"date='YYYY-MM-DD'\"                      Exact date match\n");
    printf("  \"date>='YYYY-MM-DD'\"                     Date greater than or equal\n");
    printf("  \"date<='YYYY-MM-DD'\"                     Date less than or equal\n");
    printf("  \"time>='HH:MM[:SS]'\"                     Time greater than or equal\n");
    printf("  \"time<='HH:MM[:SS]'\"                     Time less than or equal\n");
    printf("  \"level='LEVEL'\"                          Log level (ERROR, INFO, WARNING, DEBUG)\n");
    printf("  Multiple conditions can be combined with 'and'\n\n");
    printf("Examples:\n");
    printf("  %s logs.txt\n", program_name);
    printf("  %s logs.txt into \"output.csv\"\n", program_name);
    printf("  %s logs.txt filter \"date>='2024-11-13'\" into \"filtered.csv\"\n", program_name);
    printf("  %s logs.txt filter \"date>='2024-11-13' and date<='2024-11-17'\" into \"range.csv\"\n", program_name);
    printf("  %s logs.txt stats '2024-11-17'\n", program_name);
}

// Add this to store the CSV filename
char csv_filename[256] = "";

// Helper function to remove quotes from a string
void remove_surrounding_quotes(char *str) {
    size_t len = strlen(str);
    if (len >= 2 && ((str[0] == '"' && str[len-1] == '"') || 
                     (str[0] == '\'' && str[len-1] == '\''))) {
        memmove(str, str + 1, len - 2);
        str[len - 2] = '\0';
    }
}

int validate_date(const char *date_str) {
    ParsedDate date = parse_date(date_str);
    
    // Basic date validation
    if (date.year < 1900 || date.year > 9999) return 0;
    if (date.month < 1 || date.month > 12) return 0;
    if (date.day < 1 || date.day > 31) return 0;
    
    // Additional validation for days in month
    int days_in_month[] = {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    
    // Adjust February for leap years
    if (date.month == 2) {
        if ((date.year % 4 == 0 && date.year % 100 != 0) || (date.year % 400 == 0)) {
            days_in_month[2] = 29;
        }
    }
    
    if (date.day > days_in_month[date.month]) return 0;
    
    return 1;
}

// Function to parse a single filter condition with proper quote handling
int parse_filter_condition(const char *condition, int *current_or_group) {
    char type[20] = {0};
    char op[3] = {0};
    char value[30] = {0};
    char *op_pos;
    char condition_copy[256];
    int is_or = 0;
    
    // Check if condition starts with OR: or AND:
    if (strncmp(condition, "OR:", 3) == 0) {
        strncpy(condition_copy, condition + 3, sizeof(condition_copy) - 1);
        is_or = 1;
    } else if (strncmp(condition, "AND:", 4) == 0) {
        strncpy(condition_copy, condition + 4, sizeof(condition_copy) - 1);
        (*current_or_group)++;
    } else {
        strncpy(condition_copy, condition, sizeof(condition_copy) - 1);
    }
    
    // Rest of the parsing logic remains the same...
    if ((op_pos = strstr(condition_copy, ">=")) != NULL) {
        strncpy(op, ">=", 2);
    } else if ((op_pos = strstr(condition_copy, "<=")) != NULL) {
        strncpy(op, "<=", 2);
    } else if ((op_pos = strchr(condition_copy, '=')) != NULL) {
        strncpy(op, "=", 1);
    } else {
        fprintf(stderr, "Invalid filter condition: %s\n", condition_copy);
        return 0;
    }
    
    // Extract type and value...
    size_t type_len = op_pos - condition_copy;
    strncpy(type, condition_copy, type_len);
    type[type_len] = '\0';
    
    const char *value_start = op_pos + strlen(op);
    while (*value_start == ' ') value_start++;
    
    if (*value_start == '\'') {
        value_start++;
        char *value_end = strchr(value_start, '\'');
        if (value_end) {
            size_t value_len = value_end - value_start;
            strncpy(value, value_start, value_len);
            value[value_len] = '\0';
        } else {
            fprintf(stderr, "Missing closing quote in value: %s\n", value_start);
            return 0;
        }
    } else {
        strncpy(value, value_start, sizeof(value) - 1);
    }
    
    // Validation checks...
    if (strcmp(type, "date") != 0 && 
        strcmp(type, "time") != 0 && 
        strcmp(type, "level") != 0) {
        fprintf(stderr, "Invalid filter type: %s\n", type);
        return 0;
    }
    
    if (strcmp(type, "date") == 0 && !validate_date(value)) {
        fprintf(stderr, "Invalid date format or value: %s\n", value);
        return 0;
    }
    
    // If this is an OR condition, keep the same or_group
    if (!is_or) {
        (*current_or_group)++;
    }
    
    add_filter_condition(type, op, value, *current_or_group);
    return 1;
}


// Function to split filter expression into individual conditions
char** split_filter_conditions(char *filter_expr, int *count) {
    char **conditions = malloc(MAX_FILTERS * sizeof(char*));
    *count = 0;
    
    // Remove surrounding quotes from the entire expression
    remove_surrounding_quotes(filter_expr);
    
    char *condition = filter_expr;
    char *separator;
    
    while (condition && *count < MAX_FILTERS) {
        // Skip leading spaces
        while (*condition == ' ') condition++;
        
        // Find next "and" or "or" separator
        char *and_pos = strstr(condition, " and ");
        char *or_pos = strstr(condition, " or ");
        
        if (and_pos && (!or_pos || and_pos < or_pos)) {
            separator = and_pos;
            conditions[*count] = malloc(strlen(condition) + 8); // +8 for "AND" marker
            sprintf(conditions[*count], "AND:%s", condition);
            *separator = '\0';
        } else if (or_pos) {
            separator = or_pos;
            conditions[*count] = malloc(strlen(condition) + 8); // +8 for "OR" marker
            sprintf(conditions[*count], "OR:%s", condition);
            *separator = '\0';
        } else {
            conditions[*count] = malloc(strlen(condition) + 8);
            sprintf(conditions[*count], "OR:%s", condition); // Default to OR for last condition
            (*count)++;
            break;
        }
        
        (*count)++;
        condition = separator + (and_pos ? 5 : 4);  // Skip " and " or " or "
    }
    
    return conditions;
}

int parse_arguments(int argc, char **argv) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 0;
    }
    
    int i = 2;  // Start from the first optional argument
    while (i < argc) {
        if (strcmp(argv[i], "into") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Missing CSV filename after 'into'\n");
                return 0;
            }
            char *filename = argv[i + 1];
            remove_surrounding_quotes(filename);
            strncpy(csv_filename, filename, sizeof(csv_filename) - 1);
            i += 2;
            continue;
        }
        
        if (strcmp(argv[i], "filter") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Missing filter expression\n");
                return 0;
            }
            strncpy(command_type, "filter", sizeof(command_type) - 1);
            int condition_count;
            char **conditions = split_filter_conditions(argv[i + 1], &condition_count);
            
            int current_or_group = 0;
            for (int j = 0; j < condition_count; j++) {
                if (!parse_filter_condition(conditions[j], &current_or_group)) {
                    for (int k = 0; k <= j; k++) {
                        free(conditions[k]);
                    }
                    free(conditions);
                    return 0;
                }
                free(conditions[j]);
            }
            free(conditions);
            i += 2;
            continue;
        }
        
        if (strcmp(argv[i], "stats") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Missing date for stats\n");
                return 0;
            }
            strncpy(command_type, "stats", sizeof(command_type) - 1);
            char *date = argv[i + 1];
            remove_surrounding_quotes(date);
            strncpy(command_value, date, sizeof(command_value) - 1);
            i += 2;
            continue;
        }
        
        fprintf(stderr, "Invalid argument: %s\n", argv[i]);
        print_usage(argv[0]);
        return 0;
    }
    
    return 1;
}

// Add this new function to write statistics to CSV
void write_stats_to_csv(const char* filename, const char* date) {
    FILE *csv_file = fopen(filename, "w");
    if (!csv_file) {
        fprintf(stderr, "Error creating CSV file: %s\n", filename);
        return;
    }
    
    // Write CSV header
    fprintf(csv_file, "Log Level,Count\n");
    
    int error_count = 0, info_count = 0, warning_count = 0, debug_count = 0;
    int total_count = 0;
    
    if (date) {
        // Calculate daily statistics
        for (int i = 0; i < log_count; i++) {
            if (strcmp(log_entries[i].date, date) == 0) {
                if (strcmp(log_entries[i].level, "ERROR") == 0) error_count++;
                else if (strcmp(log_entries[i].level, "INFO") == 0) info_count++;
                else if (strcmp(log_entries[i].level, "WARNING") == 0) warning_count++;
                else if (strcmp(log_entries[i].level, "DEBUG") == 0) debug_count++;
                total_count++;
            }
        }
    } else {
        // Calculate overall statistics
        for (int i = 0; i < log_count; i++) {
            if (strcmp(log_entries[i].level, "ERROR") == 0) error_count++;
            else if (strcmp(log_entries[i].level, "INFO") == 0) info_count++;
            else if (strcmp(log_entries[i].level, "WARNING") == 0) warning_count++;
            else if (strcmp(log_entries[i].level, "DEBUG") == 0) debug_count++;
        }
        total_count = log_count;
    }
    
    // Write statistics to CSV
    fprintf(csv_file, "ERROR,%d\n", error_count);
    fprintf(csv_file, "INFO,%d\n", info_count);
    fprintf(csv_file, "WARNING,%d\n", warning_count);
    fprintf(csv_file, "DEBUG,%d\n", debug_count);
    fprintf(csv_file, "Total,%d\n", total_count);
    
    fclose(csv_file);
    if (date) {
        printf("\nStatistics for %s exported to %s\n", date, filename);
    } else {
        printf("\nOverall statistics exported to %s\n", filename);
    }
}

int main(int argc, char **argv) {
    if (!parse_arguments(argc, argv)) {
        return 1;
    }

    FILE *file = fopen(argv[1], "r");
    if (!file) {
        perror("Error opening log file");
        return 1;
    }

    yyin = file;
    yylex();
    fclose(file);

    if (strcmp(command_type, "stats") == 0) {
        if (strlen(csv_filename) > 0) {
            // Export daily statistics to CSV
            write_stats_to_csv(csv_filename, command_value);
        } else {
            // Display daily statistics on console
            print_daily_statistics(command_value);
        }
    } else {
        if (strlen(csv_filename) > 0) {
            if (strlen(command_type) == 0) {
                // Export overall statistics to CSV
                write_stats_to_csv(csv_filename, NULL);
            } else {
                // Export filtered logs to CSV
                write_logs_to_csv(csv_filename);
            }
        } else {
            // Display statistics and filtered logs on console
            print_log_statistics();
            print_filtered_logs();
        }
    }

    return 0;
}

int yywrap() {
    return 1;
}