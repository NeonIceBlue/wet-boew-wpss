// ************************************************************
//
// Name: puppeteer_markup_server.js
//
// $Revision: 1348 $
// $URL: svn://10.36.148.185/Crawler/Tools/puppeteer_markup_server.js $
// $Date: 2019-06-12 12:49:26 -0400 (Wed, 12 Jun 2019) $
//
// Synopsis: node puppeteer_markup_server.js <port> <chrome_path>
//                                           <user_data_directory> -debug
//
// Where: port - the port number to use for communications
//        chrome_path - path to the Chrome browser
//        user_data_directory - user data directory
//        -debug - optional debugging flag
//
// Description:
//
//    This program starts a web service that listens for actions.  The actions
// are:
//    GET - get a web page
//    EXIT - exit the service
//
// This program must be run by NodeJS.  It requires the puppeteer-core module.
//
// Terms and Conditions of Use
//
// Unless otherwise noted, this computer program source code
// is covered under Crown Copyright, Government of Canada, and is
// distributed under the MIT License.
//
// MIT License
//
// Copyright (c) 2019 Government of Canada
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// ************************************************************
var program_name = 'puppeteer_markup_server.js';
var http = require('http');
var url = require('url');
const puppeteer = require('puppeteer-core');
var fs = require('fs');
var debug = 0;
var arg, port, arg_count, t, page, server, browser;
var wsendpoint, html, user_data_directory, chrome_path;
var idle_timeout = 50000,
    idle_timer,
    received_request = 0;


// ************************************************************
//
// Name: Idle_Exit
//
// Parameters: none
//
// Description:
//
//    This function is the idle timeout callback.  It exits the
// program if the request received flag has not been set.
//
// ************************************************************
function Idle_Exit() {

    // Get the elapsed time for loading the page
    if (received_request === 0) {
        console.log('Idle timeout');
        clearTimeout(idle_timer);

        // Close any browser
        if (browser != undefined) {
            console.log('Close browser');
            (async () => {
                await browser.close();
            })();
        }
        console.log('exiting program');
        process.exit();
    } else {
        // Clear the received_request flag.
        if (debug === 1) console.log('Reset idle timer, clear received_request flag');
        received_request = 0;
        clearTimeout(idle_timer);
        idle_timer = setTimeout(Idle_Exit, idle_timeout);
    }
}

// ************************************************************
//
// Mainline
//
// ************************************************************

//
// Check for program arguments
// Skip first 2 arguments, node and javascript file name
//
process.argv.shift();
process.argv.shift();
if (process.argv.length < 3) {
    console.log('Missing program arguments');
    console.log('Usage: puppeteer_markup_server.js <portnumber> <chrome_path> <user data directory>');
    process.exit();
} else {
    // first argument is the port number, the 2nd the chrome executable
    // path and directory for user data.
    port = process.argv.shift();
    chrome_path = process.argv.shift();
    user_data_directory = process.argv.shift();
}

//
// Check for optional arguments
//
while (process.argv.length > 0) {
    //
    // Get next argument
    //
    arg = process.argv[0];
    process.argv.shift();

    //
    // Do we generate debug messages ?
    //
    if (arg === '-debug') {
        debug = 1;
    } else {
        console.log('Unknown program argument ' + arg);
        process.exit(1);
    }
}

//
// Setup an idle timer to exit the program if there is no activity
//
if (debug === 1) console.log('Set initial idle timer');
idle_timer = setTimeout(Idle_Exit, idle_timeout);
if (debug === 1) console.log('Create server on port ' + port);

// ************************************************************
//
// Name: HTTP server
//
// Parameters: req - HTTP request
//             res - HTTP response
//
// Description:
//
//    This function is an HTTP server that listens for requests
// on the specified port.  If it receives a GET request, it will
// retrieve the URL specified in the argument list, and return
// the HTML markup of that URL.  It will ignore a request for
// a favicon.ico file.  If the request is for EXIT, it exist the
// program.
//
// ************************************************************
server = http.createServer(function(req, res) {
    var get_url, q, qdata, pathname, response, headers, content_type;
    var status, user_agent;
    var page_image = 0;
    var username = "";
    var password = "";
    var page_image_file_name = "";

    //
    // Print out request URL string
    //
    if (debug === 1) console.log('server, req.url = ' + req.url);
    q = url.parse(req.url, true);
    qdata = q.query;
    pathname = q.pathname;
    received_request = 1;

    //
    // Are we requesting the favicon.ico? (i.e. we are called from a browser)
    // If so, ignore the request.
    //
    if (pathname === '/favicon.ico') {
        console.log("Ignore favicon.ico request");
        return;
    }

    //
    // Is this a request to GET a URL or exit the server?
    //
    if (pathname === '/GET' || pathname === '/EXIT') {
        //
        // Do we have a URL query parameter?  This is the URL
        // we want to get.
        //
        if (!qdata.url) {
            console.log('Missing URL in request');
            return;
        }
        get_url = qdata.url;

        //
        // Check for image file types
        //
        if (get_url.match(/\.gif$/) || get_url.match(/\.jpeg$/) || get_url.match(/\.jpg$/) || get_url.match(/\.png$/)) {
            if (debug === 1) console.log("Ignore image request");
            res.end(); //end the response
            return;
        }

        //
        // Check for PDF file types
        //
        if (get_url.match(/\.pdf$/)) {
            if (debug === 1) console.log("Ignore PDF request");
            res.end(); //end the response
            return;
        }

        //
        // Do we have a page_image query parameter? If so we have to save
        // a screenshot of the web page
        //
        if (qdata.page_image) {
            page_image = 1;
            page_image_file_name = qdata.page_image;
            if (debug === 1) console.log("Page image file name " + page_image_file_name);
        } else {
            page_image = 0;
            page_image_file_name = "";
        }

        //
        // Do we have username and password query parameters? These are
        // used if we get a 401 Unauthorized error.
        //
        if (qdata.username && qdata.password) {
            username = qdata.username;
            password = qdata.password;
            if (debug === 1) console.log("Authentication credentials " + username + " " + password);
        } else {
            username = "";
            password = "";
        }

        //
        // Reconnect to the browser
        //
        (async () => {
            //
            // Do we already have a chrome instance?
            //
            if (wsendpoint != undefined) {
                //
                // Reconnect to existing chrome instance
                //
                if (debug === 1) console.log('Reconnect to chrome');
                browser = await puppeteer.connect({
                    browserWSEndpoint: wsendpoint,
                    ignoreHTTPSErrors: true
                });

                if (browser == undefined) {
                    console.log('Failed to reconnect to chrome browser');
                    program.exit(1);
                } else {
                    if (debug === 1) console.log('Chrome reconnected');
                }
            } else {
                //
                // Launch Chrome browser instance
                //
                if (debug === 1) console.log("Launch chrome, executablePath = " +
                                             chrome_path + " userDataDir = " +
                                             user_data_directory);
                browser = await puppeteer.launch({
                    headless: true,
                    userDataDir: user_data_directory,
                    executablePath: chrome_path
                });

                //
                // Did chrome start?
                //
                if (browser == undefined) {
                    console.log('Failed to start chrome browser');
                    program.exit(1);
                } else {
                    if (debug === 1) console.log('Chrome launched');
                }

                //
                // Get endpoint to allow reconnection
                //
                wsendpoint = await browser.wsEndpoint();
                if (debug === 1) console.log('Endpoint: ' + wsendpoint);
            };

            //
            // Is this a request to exit the server?
            //
            if (pathname === '/EXIT') {
                t = new Date();
                console.log('Exit server at ' + t.toLocaleTimeString());

                //
                // Close the browser
                //
                if (browser != undefined) {
                    await browser.close();
                }
                process.exit();
            }

            //
            // Get new page object and set viewport size
            //
            if (debug === 1) {
                t = new Date();
                console.log('await browser.newPage at ' + t.toLocaleTimeString());
            }
            const page = await browser.newPage();
            user_agent = await browser.userAgent();
            await page.setUserAgent(user_agent + ' - WPSS_Tool');
            user_agent = await page.evaluate('navigator.userAgent');
            if (debug === 1) console.log('User agent string ' + user_agent);

            await page.setViewport({
                width: 1280,
                height: 847
            });

            //
            // Get the requested page
            //
            if (debug === 1) {
                t = new Date();
                console.log('page.goto at ' + t.toLocaleTimeString());
            }
            response = await page.goto(get_url);
            status = response.status();
            if (debug === 1) {
                t = new Date();
                console.log('page.content at ' + t.toLocaleTimeString());
                console.log('status ' + status);
            }

            //
            // Did we get the page?
            //
            if (!response.ok) {
                if (debug === 1) console.log('Failed to get URL');
                res.writeHead(500, {
                    'Content-Type': 'text/plain; charset=UTF-8'
                });
                res.end(); //end the response
                return;
            }

            //
            // Did we get an Unauthorized (401) response code?
            //
            if (status == 401) {
                if ((username != "") && (password != "")) {
                    //
                    // Add page credentials if we have them.
                    //
                    if (debug === 1) console.log('Add authentication credentials');
                    await page.authenticate(username, password);

                    //
                    // Get the page again
                    //
                    response = await page.goto(get_url);
                    status = response.status();
                }
            }

            //
            // Did we get the page?
            //
            if (status == 404) {
                if (debug === 1) console.log('Received 404 - Not Found error');
                res.writeHead(404, {
                    'Content-Type': 'text/plain; charset=UTF-8'
                });
                res.end(); //end the response
                return;
            }

            //
            // Check mime type of response, only handle text/html.
            // Get at the response headers
            //
            headers = response.headers();
            if (headers['content-type'] != undefined) {
                content_type = headers['content-type'];

                //
                // Is the content type HTML?
                //
                if (content_type.indexOf('html') == -1) {
                    if (debug === 1) console.log('page is not HTML ' + content_type);
                    res.end(); //end the response
                    await page.close();
                    return;
                }
            } else {
                //
                // No content-type header
                //
                if (debug === 1) console.log('Missing content-type header');
                res.end(); //end the response
                await page.close();
                return;
            }

            //
            // Get HTML markup from the page
            //
            html = await page.content();

            //
            // Do we want a screenshot for the page?
            //
            if (page_image) {
                if (debug === 1) console.log('Generate page snapshot');
                await page.screenshot({
                    path: page_image_file_name,
                    type: 'jpeg',
                    fullPage: true
                });
            }

            //
            // Write a response to the client that includes the HTML markup
            // for the requested page.
            //
            res.writeHead(200, {
                'Content-Type': 'text/plain; charset=UTF-8'
            });
            res.write('===== PAGE MARKUP BEGINS =====\n');
            res.write(html);

            // Add an HTML comment indicating this markup came from Node/Puppeteer/Headless Chrome
            res.write('\n');
            res.write('<!-- Page markup generated by Node/Puppeteer/Headless Chrome -->\n');

            res.write('\n===== PAGE MARKUP ENDS =====\n');
            res.end(); //end the response
            await page.close();
            if (debug === 1) {
                t = new Date();
                console.log('After sending response ' + get_url + ' at ' + t.toLocaleTimeString());
            }
        })();
    } else {
        //
        // Unknown request
        //
        if (debug === 1) console.log("Unknown request " + q.pathname);
        res.writeHead(500, {
            'Content-Type': 'text/plain; charset=UTF-8'
        });
        res.end(); //end the response
        return;
    }
});

//
// Start server and listen on port
//
server.listen(port);

//
// End of program, it will exit once the http server exits.
//

