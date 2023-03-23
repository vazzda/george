var fs = require('fs');
var path = require('path');
var lineReader = require('readline');
var exec = require('child_process').exec;
var lodash = require('lodash');


class User {

    constructor(name) {
        this.dirs_ = [];
        this.emails_ = [];
    }


    init() {
        this.dirs_ = User.getDirectories('./');

        var reader = lineReader.createInterface({
            input: fs.createReadStream('unsorted_users_front.list')
        });
        reader.on('line', function (line) {
            this.emails_.push(line);
        }.bind(this));
        reader.on('close', function () {
            this.printEmails_();
        }.bind(this));

    }

    printEmails_() {
        var sorted = lodash.uniq(this.emails_);
        console.log(sorted);
    }

}


User.getDirectories = function (srcpath) {
    return fs.readdirSync(srcpath).filter(function(file) {
        return fs.statSync(path.join(srcpath, file)).isDirectory();
    });
}



var user = new User();
user.init();
