Q = require 'q'
read = require 'read'
{parseXmlString} = require "libxmljs"
jenkins = require 'jenkins'

PARENT_JOB = 'ABSTRACT NodeJS WebApp'
DEF_GIT_ORG = 'salsita'

PROJECT_NAME = null
REPO_NAME = null
ORGANIZATION = null
DATA = null
USERNAME = PASSWORD = null

# Jenkins API connector object (shared between promises).
jenkinsAPI = null


ENVS = ['dev', 'qa', 'client', 'prod', 'try']


getBranch = (env) ->
  {
    dev: 'origin/develop'
    qa: 'origin/release**'
    client: 'origin/release**'
    prod: 'origin/master'
    try: 'origin/try**'
  }[env]


getTokenDict = (organization, repo, branch) ->
  {
    '//com.coravy.hudson.plugins.github.GithubProjectProperty/projectUrl': "#{organization}/#{repo}"
    '//scm//hudson.plugins.git.UserRemoteConfig/url': "#{organization}/#{repo}.git"
    '//scm/branches/hudson.plugins.git.BranchSpec/name': branch
    '//scm/browser/url': "#{organization}/#{repo}"
    '/com.tikal.jenkins.plugins.multijob.MultiJobProject/disabled': 'false'
  }

console.log "This script will create a Jenkins job for a projects for each " +
  "of the following environments: #{ENVS.join ', '}."

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
  Q.nfcall(read, {prompt: 'Github organization: ', default: DEF_GIT_ORG}).then (org) ->
    ORGANIZATION = org[0]

.then ->
  # Create a job for each of the 4 envs.
  Q.all (createJobFromTemplate(env) for env in ENVS)

.done()


cfgPostProcessFuns = {
  client: (jobCfg) ->
    console.log "client: removing GitHub push trigger (we don't want " +
      "the client env to deploy on push..."
    jobCfg.get('//com.cloudbees.jenkins.GitHubPushTrigger').remove()
    return jobCfg

  try: (jobCfg) ->
    console.log "try: removing unit test step (we don't want " +
      "to run unit tests in the try env..."
    jobCfg.get(
      '//com.tikal.jenkins.plugins.multijob.MultiJobBuilder[' +
        'phaseName/text()="unittest"]').remove()
    return jobCfg
}


# Copies `PARENT_JOB` to a new job and modifies the new job's values
# accordingly.
createJobFromTemplate = (env) ->
  # Get the parent job.
  Q.nfcall(jenkinsAPI.job.config, PARENT_JOB)

  .then (xml) ->
    console.log "#{env}: Received template from Jenkins..."
    parseXmlString xml

  # Replace the tokens.
  .then (jobCfg) ->
    for xpath, val of getTokenDict(ORGANIZATION, REPO_NAME, getBranch(env))
      elem = jobCfg.get xpath
      if ~elem.text().indexOf('[[')
        elem.text elem.text().replace(/\[\[.+\]\]/, val)
      else
        elem.text(val)

    jobCfg = cfgPostProcessFuns[env]?(jobCfg) or jobCfg
    console.log "#{env}: Replaced tokens..."

    return jobCfg

  # Tokens replaced, we have a working config => POST the config to Jenkins
  # to create a new job.
  .then (jobCfg) ->
    xml = jobCfg.toString()
    name = "#{PROJECT_NAME} #{env}"

    console.log "#{env}: Creating a new job #{name} in Jenkins..."

    Q.nfcall(jenkinsAPI.job.create, name, xml)
      .then ->
        console.log "#{env}: Job #{name} successfully created."
