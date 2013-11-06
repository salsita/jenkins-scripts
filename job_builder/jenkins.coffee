Q = require 'q'
read = require 'read'
{parseXmlString} = require "libxmljs"
jenkins = require 'jenkins'

PARENT_JOB = 'ABSTRACT NodeJS WebApp'

PROJECT_NAME = null
REPO_NAME = null
DATA = null
USERNAME = PASSWORD = null

jenkinsAPI = null

getBranch = (env) ->
  {
    dev: 'origin/develop'
    qa: 'origin/release**'
    client: 'origin/release**'
    prod: 'origin/master'
  }[env]

getTokenDict = (repo, branch) ->
  {
    '//com.coravy.hudson.plugins.github.GithubProjectProperty/projectUrl': repo
    '//scm//hudson.plugins.git.UserRemoteConfig/url': "#{repo}.git"
    '//scm/branches/hudson.plugins.git.BranchSpec/name': branch
    '//scm/browser/url': repo
    '/com.tikal.jenkins.plugins.multijob.MultiJobProject/disabled': false
  }


# Prompt for Jenkins username.
Q.nfcall(read, {prompt: 'Jenkins username: '}).then (username) ->
  USERNAME = encodeURIComponent(username[0])

# Prompt for Jenkins password.
.then ->
  Q.nfcall(read, {prompt: 'Jenkins password: ', silent: yes}).then (pwd) ->
    PASSWORD = encodeURIComponent(pwd[0])

# Try to login to Jenkins.
.then ->
  jenkinsAPI = jenkins("http://#{USERNAME}:#{PASSWORD}@jenkins:8080")
  # Test if we get an answer or an error.
  Q.nfcall(jenkinsAPI.job.config, PARENT_JOB)

.fail (err) ->
  console.log 'Invalid authentication.', err
  process.exit -1

# Prompt for Project name
.then ->
  Q.nfcall(read, {prompt: 'Project name: '}).then (name) ->
    PROJECT_NAME = name[0]

# Prompt for GitHub repo name.
.then ->
  Q.nfcall(read, {prompt: 'GitHub repo name: '}).then (name) ->
    REPO_NAME = name[0]

.then ->
  # Create a job for each of the 4 envs.
  Q.all (createJobFromTemplate(env) for env in ['dev', 'qa', 'client', 'prod'])

.done()


createJobFromTemplate = (env) ->
  # Get the parent job.
  Q.nfcall(jenkinsAPI.job.config, PARENT_JOB)

  .then (xml) ->
    console.log "#{env}: Received template from Jenkins..."
    parseXmlString xml

  # Replace the tokens.
  .then (jobCfg) ->
    for xpath, val of getTokenDict(REPO_NAME, getBranch(env))
      elem = jobCfg.get xpath
      elem.text elem.text().replace(/\[\[.+\]\]/, val)
    console.log "#{env}: Replaced tokens..."
    jobCfg

  # Tokens replaced, we have a working config => POST the config to Jenkins
  # to create a new job.
  .then (jobCfg) ->
    xml = jobCfg.toString()
    name = "#{PROJECT_NAME} #{env}"

    console.log "#{env}: Creating a new job #{name} in Jenkins..."

    Q.nfcall(jenkinsAPI.job.create, name, xml)
      .then ->
        console.log "#{env}: Job #{name} successfully created."
