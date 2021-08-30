const fs = require('fs')
const zlib = require('zlib')

const args = process.argv.slice(2)

function main() {
  let unzip = zlib.createUnzip()
  let instream = fs.createReadStream(`./node_modules/@ethersproject/testcases/testcases/${args[0]}.json.gz`)
  let outstream = fs.createWriteStream(`./resources/${args[0]}.json`)
  instream.pipe(unzip).pipe(outstream)
}
main()
