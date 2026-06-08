import argparse

parse = argparse.ArgumentParser(description="Fault Analysis")
parse.add_argument('file_name', type=str, help='Path to the fault output dictionary')
parse.add_argument('--gen_fault_list', default=False, help='Generate fault list from the output dictionary')
parse.add_argument('--filter_file', type=str, default=None, help='Path to the filter file')

args = parse.parse_args()
file_name = args.file_name
gen_fault_list = args.gen_fault_list
filter_file = args.filter_file

def extract_sig_name(line):
    if '(' in line:
        return line.split('(')[0].split('/')[-1]
    else:
        return line.split()[0].split('/')[-1]


filter = []
if filter_file:
    with open(filter_file, 'r') as f:
        lines = f.readlines()
        for line in lines:
            filter.append(line.strip().split()[1])
    f.close()

ND_faults = {}
faults = {
    'ND': {'count': 0},
    'SDC': {'count': 0},
    'Halt': {'count': 0},
    'Time out': {'count': 0}
}

with open(file_name, 'r') as f:
    lines = f.readlines()

    for line in lines:
        if filter_file and line.split()[0] not in filter:
            continue

        clas_dict = {}

        if 'ND' in line:
            clas_dict = faults['ND']
        elif 'SDC' in line:
            clas_dict = faults['SDC']
        elif 'Halt' in line:
            clas_dict = faults['Halt']
        elif 'Time out' in line:
            clas_dict = faults['Time out']
        else:
            print(f"Unknown fault type in line: {line.strip()}")

        sig_name = extract_sig_name(line)

        if sig_name not in clas_dict:
            clas_dict[sig_name] = [line]
        else:
            clas_dict[sig_name].append(line)

        clas_dict['count'] += 1
    f.close()

if not gen_fault_list:
    for class_name in faults:
        print("--" * 50)
        print(f"{class_name} Faults: {faults[class_name]['count']}")

        if faults[class_name]['count'] == 0:
            continue
        for sig_name in faults[class_name]:
            if sig_name == 'count':
                continue

            faults[class_name][sig_name].sort()

            print(f"  {sig_name} - {class_name} Fault List ({len(faults[class_name][sig_name])}):")
            for fault in faults[class_name][sig_name]:
                print(f"    {fault.strip()}")
        print()

    print()
    for class_name in faults:
        print("##" * 50)
        print(f"{class_name} Faults: {faults[class_name]['count']}")
else:
    if gen_fault_list == 'ND':
        for sig_name in faults['ND']:
            if sig_name == 'count':
                continue

            for fault in faults['ND'][sig_name]:
                fault = fault.split()
                type = fault[-1].strip()
                name = fault[0].strip()
                print(f"{type} {name} -")
    else:
        for class_name in faults:
            for sig_name in faults[class_name]:
                if sig_name == 'count':
                    continue

                for fault in faults[class_name][sig_name]:
                    fault = fault.split()
                    type = fault[-1].split(')')[-1].replace('Halted', '').strip()
                    name = fault[0].strip()
                    print(f"{type} {name} -")
