Feature: Config validation
  In order to configure feed2email
  As a feed2email user
  I want to know whether I have configured it correctly

  Scenario: Config file does not exist
    When I run `feed2email list`
    Then it should fail with:
      """
      Missing config file
      """

  Scenario: Config file has invalid permissions
    Given an empty config file with mode "0644"
    When I run `feed2email list`
    Then it should fail with:
      """
      Invalid permissions for config file
      """

  Scenario: Config file is empty
    Given an empty config file with mode "0600"
    When I run `feed2email list`
    Then it should fail with regexp:
      """
      Invalid data type .*for config file
      """

  Scenario: Config file contains an array
    Given a config file with mode "0600" and with:
      """
      []
      """
    When I run `feed2email list`
    Then it should fail with regexp:
      """
      Invalid data type .*for config file
      """

  Scenario: Config file has invalid syntax
    Given a config file with mode "0600" and with:
      """
      ,
      """
    When I run `feed2email list`
    Then it should fail with regexp:
      """
      Invalid .*syntax for config file
      """

  Scenario: Config file does not have recipient option
    Given a config file with mode "0600" and with:
      """
      {}
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option recipient missing from config file
      """

  Scenario: Config file does not have sender option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option sender missing from config file
      """

  Scenario: Config file does not have send_method option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      """
    When I run `feed2email list`
    Then it should pass with:
      """
      No feeds
      """

  Scenario: Config file has invalid send_method option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      send_method: invalid
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option send_method not one of
      """

  Scenario: Config file does not have smtp_host option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      send_method: smtp
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option smtp_host missing from config file
      """

  Scenario: Config file does not have smtp_port option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      send_method: smtp
      smtp_host: smtp.mailgun.org
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option smtp_port missing from config file
      """

  Scenario: Config file does not have smtp_user option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      send_method: smtp
      smtp_host: smtp.mailgun.org
      smtp_port: 587
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option smtp_user missing from config file
      """

  Scenario: Config file does not have smtp_pass option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      send_method: smtp
      smtp_host: smtp.mailgun.org
      smtp_port: 587
      smtp_user: postmaster@feed2email.org
      """
    When I run `feed2email list`
    Then it should fail with:
      """
      Option smtp_pass missing from config file
      """

  Scenario: Config file has smtp_pass option
    Given a config file with mode "0600" and with:
      """
      recipient: recipient@feed2email.org
      sender: sender@feed2email.org
      send_method: smtp
      smtp_host: smtp.mailgun.org
      smtp_port: 587
      smtp_user: postmaster@feed2email.org
      smtp_pass: password
      """
    When I run `feed2email list`
    Then it should pass with:
      """
      No feeds
      """
