const fs = require('fs');
const zlib = require('zlib');

async function main() {
	let unzip = await zlib.createUnzip();
	let instream = await fs.createReadStream('./node_modules/@ethersproject/testcases/testcases/hdnode.json.gz');
	let outstream = await fs.createWriteStream('./resources/hdnode.json');

	await instream.pipe(unzip).pipe(outstream);
}
main();