const fs = require('fs')
const path = require('path')

export const writeConfig = async (fromFile: string,toFile: string,key: string, value:any) => {
    let fromFullFile = getPath(fromFile);
    if (fs.existsSync(fromFullFile) == false) {
        fs.writeFileSync(fromFullFile, "{}", { encoding: 'utf8' }, err => {})
    }

    let contentText = fs.readFileSync(fromFullFile,'utf-8');
    if (contentText == "") {
        contentText = "{}";
    }
    let data = JSON.parse(contentText);
    data[key] = value;

    let toFullFile = getPath(toFile);
    fs.writeFileSync(toFullFile, JSON.stringify(data, null, 4), { encoding: 'utf8' }, err => {})
}

export const readConfig = async (fromFile: string,key: string) => {
    let fromFullFile = path.resolve(getConfigPath(), './' + fromFile + '.json')
    let contentText = fs.readFileSync(fromFullFile,'utf-8');
    let data = JSON.parse(contentText);
    return data[key];
}

function getPath(fromFile: string){
    let dir =  path.resolve(__dirname, './config');
    if (fs.existsSync(dir) == false) {
        fs.mkdirSync(dir)
    }
    return path.resolve(__dirname, './config/' + fromFile + '.json');
}

const getConfigPath = () => {
    //return "scripts/config"
    return path.resolve(__dirname, '.') + "/./config"
}

export function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}