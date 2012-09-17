
SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";




CREATE TABLE IF NOT EXISTS `characters` (
  `user` int(11) NOT NULL,
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(32) NOT NULL,
  `level` int(11) NOT NULL default '1',
  `sex` int(11) NOT NULL default '0',
  `face` int(11) NOT NULL default '1',
  `hair` int(11) NOT NULL default '1',
  `job` int(11) NOT NULL default '0',
  `deleted` int(11) NOT NULL default '0',
  `map` int(11) NOT NULL default '22',
  `x` int(11) NOT NULL default '584500',
  `y` int(11) NOT NULL default '533500',
  `zulie` int(11) NOT NULL default '0',
  `zulie_storage` int(11) NOT NULL default '0',
  `hp` int(11) NOT NULL default '126',
  `mp` int(11) NOT NULL default '75',
  `exp` int(11) NOT NULL default '0',
  `str` int(11) NOT NULL default '15',
  `dex` int(11) NOT NULL default '15',
  `int` int(11) NOT NULL default '15',
  `con` int(11) NOT NULL default '10',
  `cha` int(11) NOT NULL default '10',
  `sen` int(11) NOT NULL default '10',
  `stat_p` int(11) NOT NULL default '0',
  `skill_p` int(11) NOT NULL default '0',
  `union` int(11) NOT NULL default '0',
  `fame` int(11) NOT NULL default '0',
  `union1_p` int(11) NOT NULL default '0',
  `union2_p` int(11) NOT NULL default '0',
  `union3_p` int(11) NOT NULL default '0',
  `union4_p` int(11) NOT NULL default '0',
  `union5_p` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=19 ;



CREATE TABLE IF NOT EXISTS `inventory` (
  `id` int(11) NOT NULL auto_increment,
  `owner` int(11) NOT NULL,
  `slot` int(11) NOT NULL,
  `item` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `amount` int(11) NOT NULL default '1',
  `durability` int(11) NOT NULL default '40',
  `lifespan` int(11) NOT NULL default '100',
  `appraised` int(11) NOT NULL default '0',
  `stats` int(11) NOT NULL default '0',
  `refined` int(11) NOT NULL default '0',
  `socket` int(11) NOT NULL default '0',
  `gem` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=41 ;
