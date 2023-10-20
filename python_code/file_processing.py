import pandas as pd
import re

# Load and process data from two files
column = ['Timestamp', 'ID', 'Text']
df = pd.read_csv('D:\\360MoveData\\Users\\DELL\\Desktop\\hiwi_work\\MRI_data\\MR3\\mr3-eventlog-2015-conv.txt', sep='\t', header=None, names=column, usecols=[0,2,3])
df['Timestamp'] = pd.to_datetime(df['Timestamp'], format='%Y%m%d%H%M%S')
df['Timestamp'] = df['Timestamp'].dt.strftime('%Y%m%d%H%M%S')
df['Text'] = df['Text'].apply(lambda x: re.sub(r"Protocol: '(.*?)', Sequence: '(.*?)'", r"Protocol: \1, Sequence: \2", str(x)))

# Filtering the rows based on the text column
phrases_to_keep = [
    "Scanner is not online",
    "Scanner is booting.",
    "Start measurement.",
    "Measurement finished OK.",
    "The user started and confirmed Host - Shutdown All by EndSession"
]
df = df[df['Text'].apply(lambda x: any(phrase in str(x) for phrase in phrases_to_keep))]
sequences_to_remove = ["Sequence: %AdjustSeq%", "Sequence: %CustomerSeq%"]
df = df[~df['Text'].str.contains('|'.join(sequences_to_remove))]
df.to_csv('mr3_merged.txt', index=False, sep = '\t', header=None)

# Function to sort "Start measurement" and "Measurement finished OK" lines
def sort_protocol_sequence(inputlines):
    sorted_lines = []
    pending_starts = {}
    all_lines = []
    pattern = r'\(Protocol: (.*?), Sequence: (.*?)\)'
    for line in inputlines:
        if "\t" in line:
            timestamp = line.split("\t")[0]

            match = re.search(pattern, line)
            if match:
                protocol = match.group(1).strip()
                sequence = match.group(2).strip()
                pair_key = (protocol, sequence)

                if "103" in line.split("\t"):
                    pending_starts[pair_key] = line
                elif "104" in line.split("\t"):
                    start = pending_starts.get(pair_key)
                    if start:
                        all_lines.extend([(timestamp, start), (timestamp, line)])
                        del pending_starts[pair_key]
                    else:
                        all_lines.append((timestamp, line))
            else:
                all_lines.append((timestamp, line))
        else:
            sorted_lines.append(line)

    all_lines.sort(key=lambda x: x[0])
    sorted_lines.extend([re.sub(r',+$', '', x[1]) for x in all_lines])

    return sorted_lines

input_file_path = 'mr3_merged.txt'
output_file_path = 'mr3_log_selected.txt'

with open(input_file_path, 'r') as file:
    lines = file.readlines()
sorted_lines = sort_protocol_sequence(lines)
sorted_lines = [line.replace('\t', ',') for line in sorted_lines]

with open(output_file_path, 'w') as file:
    file.writelines(sorted_lines)




