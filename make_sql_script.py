from glob import glob
import os
import csv
from tqdm import tqdm
from datetime import datetime
'''
    Generates auxiliary script for loading the data to a MySQL database
'''
def get_files_from_path(folder:str, recursive:bool = True, extensions:list =None) -> list:
    '''
        returns paths from specified folder and extensions
        args:
            folder: folder path to get all the files
            recursive: search recursively for all files
            extensions: extensions to get
        return:
            list of all files
    '''
    if recursive:
        all_files = glob(os.path.join(folder,'**','*'), recursive=True)
    else:
        all_files = glob(os.path.join(folder,'*'), recursive=False)
    if extensions is None:
        files = all_files
    else:
        files = []
        for fil in all_files:
            fil = str(fil)
            if os.path.splitext(fil)[1] in extensions:
                files.append(fil)
    return files

if __name__ == "__main__":
    lines = ['USE project_rides']
    # loads csv files
    csv_paths = get_files_from_path('./data', extensions=['.csv'])
    for path in tqdm(csv_paths):
        #reads the first line with column names
        with open(path, 'r') as f:
            col_names = f.readline()
        #checks by the name of the first column which table to insert the data
        first_cell = col_names.split(',')[0]
        if first_cell[0] == '"' and first_cell[-1] == '"':
            first_cell = first_cell[1:-1]

        if first_cell == 'ride_id':
            table_name = 'rides_recent'
        elif any([first_cell == x for x in 
                  ('trip_id', '01 - Rental Details Rental ID')]):
            table_name = 'rides_old'
        else:
            print('Unrecognized format: ' + path)
            continue

        # fixes MySQL not reading '' as NULL
        # also replaces datetimes with the format '%Y-%m-%d %H:%M:%S' that MySQL can
        # recognize
        with open(path) as f:
            readed = list(csv.reader(f))
        for i, entry in enumerate(readed):
            if i == 0:
                continue
            for j, cell in enumerate(entry):
                if cell == '':
                    readed[i][j] = '\\N' #works with entries encapsulated with double quotes or not, may not work
                    # with other sql dialects
            if table_name == 'rides_old':
                si = 1
                ei = 2
            else:
                si = 2
                ei = 3
            ok_date = False
            for date_format in ['%Y-%m-%d %H:%M:%S', '%m/%d/%Y %H:%M', '%m/%d/%Y %H:%M:%S', '%Y-%m-%d %H:%M']:
                try:
                    datestart = str(datetime.strptime(entry[si], date_format))
                    ok_date = True
                    if date_format != '%Y-%m-%d %H:%M:%S':
                        readed[i][si] = datestart
                        readed[i][ei] = str(datetime.strptime(entry[ei], date_format))
                except:
                    pass
            if not ok_date:
                print('broken date: ' + entry[1])
                assert False
        with open(path, 'w') as f:
            csv.writer(f).writerows(readed)
        

        path = os.path.abspath(path)
        # https://dev.mysql.com/doc/refman/8.0/en/load-data.html, 
        # had to use '\r\n', otherwise the last column doesn't read nulls
        lines += ["LOAD DATA LOCAL INFILE '{}' \n\
                    INTO TABLE {} \n\
                    FIELDS TERMINATED BY ',' \n\
                    ENCLOSED BY '\"' \n\
                    LINES TERMINATED BY '\\r\\n' \n\
                    IGNORE 1 ROWS\
                ".format(path, table_name)]
    #join all lines
    sql_script = ';\n'.join(lines) + ';'
    with open('load_csv.sql', 'w') as w:
        w.write(sql_script)
    print('SQL script ready')