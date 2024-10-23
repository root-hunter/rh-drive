const formatBytes = (bytes, decimals = 2) => {
    if (bytes === 0) return '0 Bytes';
  
    const k = 1024; // Define the conversion factor (1 KB = 1024 bytes)
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']; // Units
  
    const i = Math.floor(Math.log(bytes) / Math.log(k)); // Determine the index for the unit
    const size = parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)); // Convert bytes to the appropriate size
  
    return `${size} ${sizes[i]}`; // Return the size with the correct unit
}

const formatTextColumn = (columnName) => (_data, _type, row) => {
    const text = row[columnName];
    return text;
};

const formatByteColumn = (columnName) => (_data, _type, row) => {
    const bytes = row[columnName];
    return `${formatBytes(bytes)}`;
};

const formatDateColumn = (columnName) => (_data, _type, row) => {
    const isoDate = row[columnName];
    const date = new Date(isoDate);

    console.log(row)

    const formattedDate = date.toLocaleDateString();
    const formattedTime = date.toLocaleTimeString();

    return `${formattedDate} ${formattedTime}`;
};